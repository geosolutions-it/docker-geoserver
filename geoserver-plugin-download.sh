#!/usr/bin/env bash

set -e
set -u

[ "$#" -le "1" ] && ( echo "no plugin urls passed, exiting" ) && exit 0

PLUGIN_INSTALL_PATH=$1

for url in "${@:2}"
do
    case "$url" in
        *sourceforge*) wget "$url/download" && unzip -o ./download -d ${PLUGIN_INSTALL_PATH} && rm ./download
        ;;
        *) wget -O ./download "$url" && unzip -o ./download -d ${PLUGIN_INSTALL_PATH}
        ;;
    esac
done