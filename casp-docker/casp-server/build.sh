#!/bin/bash
version=${UNBOUND_VERSION:-2007}
declare INSTALLER_URLS=(
    ["2007"]="https://repo.dyadicsec.com/casp/releases/2007/1.0.2007.46326/centos/casp-1.0.2007.46326-RHES.x86_64.rpm"
)
install_url=${INSTALLER_URLS[$version]}
echo "Installing from ${install_url}"
tag=${UNBOUND_REPO:-unboundukc}/casp-server:${version}

docker build -t $tag \
     --build-arg CASP_SERVER_INSTALLER_URL=$install_url \
    $(dirname "$0")