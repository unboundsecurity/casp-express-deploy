#!/bin/bash
set -e

install() {
  echo "Setting up CASP..."

  if [ -d "/opt/casp-bot" ]
  then
    if [ -f /opt/casp-bot/id ]; then
      rm /opt/casp-bot/id
    fi
    if [ -f /opt/casp-bot/activation_code ]; then
      rm /opt/casp-bot/activation_code
    fi
  fi

  echo "Waiting for Database: $PGHOST..."
  until $(psql -w --host $PGHOST -U $PGUSER -lqt 2> /dev/null | cut -d \| -f 1 | grep -qw $PGDATABASE); do
    sleep 5
  done

  echo "Setting up CASP database schema"
  psql -w --host $PGHOST -U $PGUSER -d $PGDATABASE -f /opt/casp/sql/casp-postgresql.sql &>/dev/null

  echo setup UKC
  echo "Waiting for $UKC_EP..."
  until $(ping -c1 $UKC_EP &>/dev/null); do
    sleep 5
  done
  until $(curl -k https://$UKC_EP:8443/api/v1/health &>/dev/null); do
    sleep 5
  done
  echo "$UKC_EP is ready"
  
  echo "Connecting to UKC..."
  UKC_COUNTER=0
  until [ $UKC_COUNTER -gt 12 ] ||  $(casp_setup_ukc --ukc-url https://$UKC_EP:8443 --ukc-user user@$UKC_PARTITION --ukc-password $UKC_PARTITION_USER_PASSWORD 2> /dev/null | grep -qw 'UKC health check was successful'); do
    let UKC_COUNTER+=1
    sleep 5
  done
  if ! $(casp_check_ukc 2> /dev/null | grep -qw 'UKC health check was successful') 
  then
    echo "Cannot connect to UKC"
    casp_setup_ukc --ukc-url https://$UKC_EP:8443 --ukc-user user@$UKC_PARTITION --ukc-password $UKC_PARTITION_USER_PASSWORD --verbose
    exit 1
  fi 
  
  echo "Setting up database"
  casp_setup_db --db-url jdbc:postgresql://$PGHOST:5432/$PGDATABASE --db-user $PGUSER --db-password $PGPASSWORD --db-driver org.postgresql.Driver --db-driver-path /opt/casp/jdbc/postgresql-42.2.5.jar &>/dev/null

  if [ ! -z "$CASP_FIREBASE_TOKEN" ]
  then
    echo "firebase.apikey=$CASP_FIREBASE_TOKEN" >> /etc/unbound/casp.conf
  fi
  
  if [ ! -z "$BLOCKSET_TOKEN" ]
  then
    if [ -f "/usr/bin/casp_setup_wallets" ]; 
    then
      casp_setup_wallets --blockset-token $BLOCKSET_TOKEN 
    fi
  fi

  if [ ! -z "$INFURA_PROJECTID" ]
  then
    if [ -f "/usr/bin/casp_setup_wallets" ]; 
    then
      casp_setup_wallets --infura-project-id $INFURA_PROJECTID
    fi
  fi

  # Enabling trace log
  sed -i -e 's/Logger name="TRACE" additivity="false" level="off"/Logger name="TRACE" additivity="false" level="debug"/g' /etc/unbound/log4j/casp.xml
  
  touch /casp-installed
}



post_install() {
  if [ ! -z "$CASP_SO_PASSWORD" ]
  then
    echo "Executing post install commands"
    # load tomcat to execute rest based setup steps
    /opt/casp/tomcat/bin/startup.sh &>/dev/null
    until $(curl --output /dev/null --silent --head --fail http://localhost:8080/casp/api/v1.0/mng/status); do
      sleep 5
    done

    set_password
    create_account
  fi
}

start() {
  echo "Starting CASP..."
  /opt/casp/tomcat/bin/startup.sh &>/dev/null
  nohup /usr/bin/bash /opt/casp/providers/wallets/scripts/start.sh &>/dev/null &

  /usr/sbin/httpd &>/dev/null

  echo 'Checking CASP status...'
  until $(curl --output /dev/null --silent --head --fail -k https://localhost/casp/api/v1.0/mng/status); do
    sleep 5
  done
  echo 'CASP is ready'
}

set_password() {
  if [ ! -z "$CASP_SO_PASSWORD" ]
  then
    echo "Changing password"
    password=$(echo -n "so:casp" | base64)

    until $(curl -k -s --fail --request PUT \
    --url http://localhost:8080/casp/api/v1.0/mng/auth/password \
    --header "authorization: Basic $password" \
    --header 'content-type: application/json' \
    --data "{
      \"value\": \"$CASP_SO_PASSWORD\"
    }"); do
      sleep 5
    done
    echo "Password changed"
  fi
}
create_access_token() {
  echo "Creating access token"
  password=$(echo -n "so:$CASP_SO_PASSWORD" | base64)

  until $([ ! -z "$access_token" ]); do
    access_token=$( \
    curl -k -s --request POST \
      --url http://localhost:8080/casp/api/v1.0/mng/auth/tokens \
      --header "authorization: Basic $password" \
      --header 'content-type: application/json' \
      --data "{
      \"grant_type\": \"password\"
    }" \
    | python -m json.tool | grep "access_token" | awk "{print \$NF}" | sed -e 's/"//' | sed -e 's/"//' | sed -e 's/,//')
  done
}

create_account() {
  if [ ! -z "$CASP_ACCOUNT" ]
  then
    create_access_token

    echo "Creating an account"
    account_id=$( \
    curl -k -s --request POST \
      --url http://localhost:8080/casp/api/v1.0/mng/accounts \
      --header 'authorization: Bearer '$access_token \
      --header 'content-type: application/json' \
      --data "{
      \"name\": \"$CASP_ACCOUNT\",
      \"isGlobal\": \"false\"
    }" \
    | python -m json.tool | grep "id" | awk "{print \$NF}" | sed -e 's/"//' | sed -e 's/"//' | sed -e 's/,//')
  fi
}

case "$1" in
  start)
    if [ -e "/casp-installed" ]; then
        echo "CASP Installed"
        echo "Waiting for $UKC_EP"
        until $(ping -c1 $UKC_EP &>/dev/null); do
          sleep 5
        done
        until $(curl -k https://$UKC_EP:8443/api/v1/health &>/dev/null); do
          sleep 5
        done
        echo "$UKC_EP is ready"
    else 
        install
        post_install
    fi 
    start

    tail -f /dev/null
  ;;
esac