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

setup_dc() {
  template_id=`curl -k -s --request GET \
    --url https://$CASP/casp/api/v1.0/mng/attributeTemplates \
    --header 'authorization: Bearer '$access_token \
  | jq '.items[].id' -M | grep '"txrisk"' --color=never | tr -d '"'`
  until $([ ! -z "$template_id" ]); do
    template_id=$( \
      curl -k -s --request POST \
      --url https://$CASP/casp/api/v1.0/mng/attributeTemplates \
      --header 'authorization: Bearer '$access_token \
      --header 'content-type: application/json' \
      --data "{
        \"id\": \"txrisk\",
        \"description\": \"\",
        \"type\": \"numeric\",
        \"range\":{\"min\":1,\"max\":100}
      }" \
      | jq '.id' -M | tr -d '"')
      sleep 1
  done
  echo "Template id: $template_id"
  group_id=`curl -k -s --request GET \
    --url https://$CASP/casp/api/v1.0/mng/attributeTemplateGroups \
    --header 'authorization: Bearer '$access_token \
  | jq '.items[].id' -M | grep '"group1"' --color=never | tr -d '"'`
  until $([ ! -z "$group_id" ]); do
    group_id=$( \
      curl -k -s --request POST \
      --url https://$CASP/casp/api/v1.0/mng/attributeTemplateGroups \
      --header 'authorization: Bearer '$access_token \
      --header 'content-type: application/json' \
      --data "{
        \"id\": \"group1\",
        \"description\": \"\",
        \"attributeTemplates\":[\"$template_id\"]
      }" \
      | jq '.id' -M | tr -d '"')
      sleep 1
  done
  echo "Group id: $group_id"
  collector=`curl -k -s --request GET \
    --url https://$CASP/casp/api/v1.0/mng/dataCollectors \
    --header 'authorization: Bearer '$access_token \
  | jq -M '.items[] | select(.name=="collector1")'`
  until $([ ! -z "$collector" ]); do
    collector=$( \
      curl -k -s --request POST \
      --url https://$CASP/casp/api/v1.0/mng/dataCollectors \
      --header 'authorization: Bearer '$access_token \
      --header 'content-type: application/json' \
      --data "{
        \"name\": \"collector1\",
        \"description\": \"\",
        \"attributeTemplateGroupId\": \"$group_id\"
      }" \
      | jq '.' -M)
    if [ ! -z "$collector" ]; then
      activation_code=$( echo $collector | jq '.activationCode' | tr -d '"')
    else
      sleep 1
    fi
  done
  datacollectorid=$( echo $collector | jq '.id' | tr -d '"')
  echo $datacollectorid > /dc_id.txt
  echo "Data collector id: $datacollectorid"
  state=$( echo $collector | jq '.state' | tr -d '"')
  if [ "$state" = "NOT_ACTIVATED" ]; then
    until $([ ! -z "$activation_code" ]); do
      activation_code=$( \
        curl -k -s --request PUT \
        --url https://$CASP/casp/api/v1.0/mng/dataCollectors/$datacollectorid/activationCode \
        --header 'authorization: Bearer '$access_token \
        --header 'content-type: application/json' \
        --data "{}" \
        | jq '.activationCode' -M | tr -d '"')
      sleep 1
    done
    java -jar /casp-dc/bin/DataCollector.jar -i $datacollectorid -c $activation_code -w $BOT_DC_PASSWORD -v true -u https://$CASP/casp -k
  fi
  echo "done"
}

start() {
  echo "Starting CASP DATA COLLECTOR..."
  echo "txrisk=12" > /casp-dc/bin/result.txt
  java -jar /casp-dc/bin/DataCollector.jar -i $datacollectorid -w $BOT_DC_PASSWORD -v true -u https://$CASP/casp -k -f /casp-dc/bin/result.txt > /proc/1/fd/1 2>&1 &
}

wait_for_casp
create_access_token
setup_dc

start
