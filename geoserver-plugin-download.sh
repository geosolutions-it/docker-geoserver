#!/usr/bin/env bash

[ "$#" -ne 2 ] && ( echo "no plugin urls passed, exiting" ) && exit 0

PLUGIN_INSTALL_PATH=$1

for url in "$@"
do
    case "$url" in
        *sourceforge*) wget "$url/download" && unzip -o ./download -d ${PLUGIN_INSTALL_PATH} && rm ./download
        ;;
        *) wget -O ./${url##*/} "$url" && unzip -o ./${url##*/} -d ${PLUGIN_INSTALL_PATH}
        ;;
    esac
done