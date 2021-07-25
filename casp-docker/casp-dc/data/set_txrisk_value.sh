#!/bin/bash
set -e

if [ $# -eq 0 ]
  then
    echo "No arguments supplied. You need to specify txrisk value."
fi

echo "Saving txrisk into /casp-dc/bin/result.txt file."
echo "Saving txrisk into /casp-dc/bin/result.txt file." > /proc/1/fd/1
echo "txrisk=$1" > /casp-dc/bin/result.txt

/restart_dc.sh