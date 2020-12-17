#!/usr/bin/env bash

CURL=$(which curl) 

$CURL --connect-timeout 2 -m 2 -f -q -u admin:geoserver "http://localhost:8080/geoserver/gwc/rest/layers" || ( echo "test failed" && exit 2 )

