#!/usr/bin/env bash

set -euo pipefail

if [ "$#" -le 1 ]; then
    echo "no plugin urls passed, exiting"
    exit 0
fi

PLUGIN_INSTALL_PATH=$1
shift

for url in "$@"; do
    case "$url" in
        *sourceforge*)
            wget -O ./download "$url/download"
            unzip -o ./download -d "$PLUGIN_INSTALL_PATH"
            rm -f ./download
        ;;
        *)
            archive_name=${url##*/}
            wget -O "./$archive_name" "$url"
            unzip -o "./$archive_name" -d "$PLUGIN_INSTALL_PATH"
        ;;
    esac
done
