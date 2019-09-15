#!/bin/bash

docker-compose up -d

echo "Waiting for CASP"
while :
do
    docker logs casp-docker_casp-bot_1 2>&1  | grep -q 'Starting to approve operations'
    if [ $? -eq 0 ]; then
        break
    fi
    sleep 10
done

echo "CASP is ready"
