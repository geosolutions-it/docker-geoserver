#!/usr/bin/env bash

CURL=$(which curl) 
catalina.sh run &
printenv
sleep 5
$CURL --retry 60 -u admin:geoserver "http://$HOSTNAME:8080/geoserver/gwc/rest/layers"

netstat -lutanp
