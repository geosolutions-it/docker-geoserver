#!/usr/bin/env bash

CURL=$(which curl) 

$CURL --retry 60 --retry-delay 1 --fail \
-u admin:geoserver "http://localhost:8080/geoserver/gwc/rest/layers" || ( echo "test failed" && exit 2 )

