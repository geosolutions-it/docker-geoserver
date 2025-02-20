#!/usr/bin/env bash

set -e
set -u

[ "$#" -le "1" ] && ( echo "no plugin urls passed, exiting" ) && exit 0

PLUGIN_INSTALL_PATH=$1

for url in "${@:2}"
do
    # support specifying SourceForge URLs without the `/download` part at the end necessary for downloading
    if [[ "$url" == *sourceforge* ]]; then
        url="$url/download"
    fi

    wget -O ./download "$url"
    unzip -o ./download -d ${PLUGIN_INSTALL_PATH}
    rm ./download
done
