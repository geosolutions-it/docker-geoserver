#!/usr/bin/env bash
geoserver-plugin-download.sh ${CATALINA_BASE}/webapps/${APP_LOCATION} $PLUGIN_DYNAMIC_URLS
set -m
catalina.sh run &
/usr/local/bin/geoserver-rest-config.sh
fg %1
