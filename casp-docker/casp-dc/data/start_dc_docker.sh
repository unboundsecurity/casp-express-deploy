#!/bin/bash

set -e

while [[ "$(curl -s -k -o /dev/null -w ''%{http_code}'' https://${CASP}:443/casp/api/v1.0/mng/status)" != "200" ]];
  do sleep 5;
done
sleep 15

/start_dc.sh

while true; do sleep 86400; done
