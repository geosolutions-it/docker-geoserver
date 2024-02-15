#!/usr/bin/env bash
geoserver-plugin-download.sh ${CATALINA_BASE}/webapps/${APP_LOCATION}/WEB-INF/lib $PLUGIN_DYNAMIC_URLS
set -m
export CATALINA_OPTS="$CATALINA_OPTS $EXTRA_GEOSERVER_OPTS"
catalina.sh run &
/usr/local/bin/geoserver-rest-config.sh
fg %1
