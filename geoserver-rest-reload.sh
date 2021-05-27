#!/usr/bin/env bash
#while [ "$(curl -s --retry-connrefused --retry 100 -I http://localhost:8080/geoserver/web/ 2>&1 |grep 200)" == "" ];do
#  echo "Waiting for GeoServer to be Up and running"
#done  
if [ "$ADMIN_PASSWORD" != "" ]; then
    ADMIN_HEADER=$(echo -n "admin:${ADMIN_PASSWORD}")    
else
    ADMIN_HEADER=$(echo -n "admin:geoserver")
if 
curl -H "Authorization: basic ${ADMIN_HEADER}" -X GET http://localhost:8080/geoserver/rest/reload -H  "accept: application/json" -H  "content-type: application/json"