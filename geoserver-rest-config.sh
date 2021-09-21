#!/usr/bin/env bash
while [ "$(curl -s --retry-connrefused --retry 100 -I http://localhost:8080/geoserver/web/ 2>&1 |grep 200)" == "" ];do
  echo "Waiting for GeoServer to be Up and running"
done  
if [ "$ADMIN_PASSWORD" != "" ]; then
    echo "GeoServer password is likely to be default, going to change to new admin password."
    ADMIN_HEADER=$(echo -n "admin:geoserver" | base64)
    curl -H "Authorization: basic $ADMIN_HEADER" -X PUT http://localhost:8080/geoserver/rest/security/self/password -H  "accept: application/json" -H  "content-type: application/json" -d "{  \"newPassword\": \"$ADMIN_PASSWORD\"}"
fi  
