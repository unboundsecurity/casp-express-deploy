#!/bin/bash
source ../../../installer_urls.sh
version=${UB_VER:-2007}
ver_id="CASP_SERVER_INSTALLER_URL_$version"
install_url=${!ver_id}
echo "Installing from ${install_url}"
tag=${UNBOUND_REPO:-unboundukc}/casp-server:${version}

docker build -t $tag \
     --build-arg CASP_SERVER_INSTALLER_URL=$install_url \
    $(dirname "$0")