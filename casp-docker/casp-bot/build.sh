#!/bin/bash
version=${UNBOUND_VERSION:-2007}
declare SDK_URLS=(
    ["2007"]="https://repo.dyadicsec.com/casp/releases/2007/1.0.2007.46326/centos/casp-sdk-package.1.0.2007.46326.RHES.x86_64.tar.gz"
)
install_url=${SDK_URLS[$version]}
echo "Installing from ${install_url}"
tag=${UNBOUND_REPO:-unboundukc}/casp-bot:${version}

docker build -t $tag --build-arg CASP_SDK_URL="${install_url}" \
   $(dirname "$0")