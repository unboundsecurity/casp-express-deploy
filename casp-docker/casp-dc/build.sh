#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $SCRIPT_DIR/../../../installer_urls.sh
version=${UB_VER:-2007}
ver_id="CASP_SDK_URL_$version"
install_url=${!ver_id}
echo "Installing from ${install_url}"
tag=${UNBOUND_REPO:-unboundukc}/casp-dc:${version}

docker build -t $tag --build-arg CASP_SDK_URL="${install_url}" \
   $(dirname "$0")
