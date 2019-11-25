#!/bin/bash
set -e

wait_for_casp() {
  echo 'Checking CASP status...'
  until $(curl --output /dev/null --silent --head --fail -k https://$CASP/casp/api/v1.0/mng/status); do
    sleep 5
  done
  echo 'CASP is Ready'
}

create_access_token() {
  echo "Creating access token"
  password=$(echo -n "so:$CASP_SO_PASSWORD" | base64)

  until $([ ! -z "$access_token" ]); do
    access_token=$( \
    curl -k -s --request POST \
      --url https://$CASP/casp/api/v1.0/mng/auth/tokens \
      --header "authorization: Basic $password" \
      --header 'content-type: application/json' \
      --data "{
      \"grant_type\": \"password\"
    }" \
    | python -m json.tool | grep "access_token" | awk "{print \$NF}" | sed -e 's/"//' | sed -e 's/"//' | sed -e 's/,//')
  done
}

find_casp_account() {
  echo "Finding CASP account..."
  #assuming only one account is available
  until $([ ! -z "$account_id" ]); do
    account_id=$( \
    curl -k -s --request GET \
      --url https://$CASP/casp/api/v1.0/mng/accounts \
      --header 'authorization: Bearer '$access_token \
      --header 'content-type: application/json' \
    | python -m json.tool | grep "id" | awk "{print \$NF}" | sed -e 's/"//' | sed -e 's/"//' | sed -e 's/,//')
  done
}

add_bot_participant() {
  find_casp_account
  echo "Creating BOT participant..."
  until $([ ! -z "$bot_id" ]); do
    bot_id=$( \
    curl -k -s --request POST \
    --url http://$CASP/casp/api/v1.0/mng/accounts/$account_id/participants \
    --header 'authorization: Bearer '$access_token \
    --header 'content-type: application/json' \
    --data "{
        \"name\": \"$BOT_NAME\",
        \"email\": \"$BOT_NAME@casp\",
        \"role\":\"\"
    }" \
    | python -m json.tool | grep "id" | awk "{print \$NF}" | sed -e 's/"//' | sed -e 's/"//' | sed -e 's/,//')
  done

  until $([ ! -z "$activation_code" ]); do
    activation_code=$( \
    curl -k -s --request POST \
    --url https://$CASP/casp/api/v1.0/mng/participants/$bot_id/reactivate \
    --header 'authorization: Bearer '$access_token \
    --header 'content-type: application/json' \
    | python -m json.tool | grep "activationCode" | awk "{print \$NF}" | sed -e 's/"//' | sed -e 's/"//' | sed -e 's/,//')
  done
}

activate() {
  if [ ! -z "$CASP_SO_PASSWORD" ]
  then
    create_access_token
    add_bot_participant
  else
    if [ ! -z "$BOT_ID" ] && [ ! -z "$BOT_ACTIVATION_CODE" ]
    then
      bot_id=$BOT_ID
      activation_code=$BOT_ACTIVATION_CODE
    else
      echo "Missing activation paramters, aborting"
      exit 1
    fi
  fi
  echo "Activiating CASP BOT $bot_id ..."
  cd /bot
  java -Djava.library.path=./bin -jar bin/BotSigner.jar -p $bot_id -c $activation_code -w 123456 -u http://$CASP/casp
  echo $bot_id > id
  touch /bot-activated
}



start() {
  cd /bot
  id=`cat id`
  echo "Starting CASP BOT $id ..."
  java -Djava.library.path=./bin -jar bin/BotSigner.jar -p $id -w 123456 -u http://$CASP/casp
}

wait_for_casp
if [ -e "/bot-activated" ]; then
  echo "CASP BOT is activated"
else 
  activate
fi 

start

