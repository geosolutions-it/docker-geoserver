#!/usr/bin/env bash

CURL=$(which curl) 

printenv

$CURL --retry 60 ---connect-timeout 5 -retry-delay 1 -u admin:geoserver "http://$HOSTNAME:8080/geoserver/gwc/rest/layers"


