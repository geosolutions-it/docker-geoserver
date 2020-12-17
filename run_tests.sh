#!/usr/bin/env bash

CURL=$(which curl) 
catalina.sh run &
printenv
sleep 15
ls -la webapps/geoserver/
$CURL --retry-delay 1 --retry 60 -X GET http://$HOSTNAME:8080/geoserver/rest/about/manifest -H  "accept: application/json" -H  "content-type: application/json"
