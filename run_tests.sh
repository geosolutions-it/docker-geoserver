#!/usr/bin/env bash

CURL=$(which curl) 

printenv

$CURL --retry 60 --retry-delay 1 --fail \
-u admin:geoserver "http://$HOSTNAME:8080/geoserver/gwc/rest/layers" || ( echo "test failed" && exit 2 )


