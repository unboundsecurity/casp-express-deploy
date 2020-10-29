#!/bin/bash
source ../../../installer_urls.sh
version=${UB_VER:-2007}
ver_id="CASP_SDK_URL_$version"
install_url=${!ver_id}
echo "Installing from ${install_url}"
tag=${UNBOUND_REPO:-unboundukc}/casp-bot:${version}

docker build -t $tag --build-arg CASP_SDK_URL="${install_url}" \
   $(dirname "$0")