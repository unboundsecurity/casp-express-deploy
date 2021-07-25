#!/bin/bash
set -e

if [ $# -eq 0 ]
  then
    echo "No arguments supplied. You need to specify txrisk value."
fi

/stop_dc.sh

datacollectorid=$( cat /dc_id.txt )
echo "Data collector id: $datacollectorid"
echo "Data collector id: $datacollectorid" > /proc/1/fd/1

java -jar /casp-dc/bin/DataCollector.jar -i $datacollectorid -w $BOT_DC_PASSWORD -v true -u https://$CASP/casp -k -f /casp-dc/bin/result.txt > /proc/1/fd/1 2>&1 &