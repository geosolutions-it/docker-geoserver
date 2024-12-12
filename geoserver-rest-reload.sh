#!/usr/bin/env bash
set -x

if [ -z "${APP_LOCATION}" ]; then
    APP_LOCATION="geoserver"
fi

#while [ "$(curl -s --retry-connrefused --retry 100 -I http://localhost:8080/geoserver/web/ 2>&1 |grep 200)" == "" ];do
#  echo "Waiting for GeoServer to be Up and running"
#done
if [ "$ADMIN_PASSWORD" != "" ]; then
    ADMIN_HEADER=$(echo -n "admin:${ADMIN_PASSWORD}" | base64)
else
    ADMIN_HEADER=$(echo -n "admin:geoserver"| base64)
fi

curl -H "Authorization: basic ${ADMIN_HEADER}" -X POST http://localhost:8080/"$APP_LOCATION"/rest/reload -H  "accept: application/json" -H  "content-type: application/json"
