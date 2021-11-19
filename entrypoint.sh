#!/usr/bin/env bash
geoserver-plugin-download.sh ${CATALINA_BASE}/webapps/${APP_LOCATION}/WEB-INF/lib $PLUGIN_DYNAMIC_URLS

export GEOSERVER_PROPERTES="# Authorization Service
starogc.authorization.host=localhost
starogc.authorization.port=7035
starogc.authorization.path=startrk-authorisation-service/authorisation
idm.authorization.host=localhost
idm.authorization.port=7193
# RTMPS Oracle Data Store
starogc.oracle.rtmps.host=$ORACLE_HOST
starogc.oracle.rtmps.port=$ORACLE_PORT
starogc.oracle.rtmps.database=(DESCRIPTION=(ADDRESS_LIST=(ADDRESS=(PROTOCOL=TCP)(HOST=$ORACLE_HOST)(PORT=1535)))(CONNECT_DATA=(SERVICE_NAME=$ORACLE_SERVICE_NAME)))
starogc.oracle.rtmps.schema=rtmps
starogc.oracle.rtmps.user=rtmps
starogc.oracle.rtmps.passwd=$ORACLE_RTMPS_PASSWORD"

export CATALINA_OPTS_GEO="GEOSERVER_BASE="/var/geoserver"
CATALINA_OPTS="-Xms4000m -Xmx4000m -Djava.awt.headless=true -XX:+UseParallelGC -XX:+UseParallelOldGC -Duser.timezone=UTC -DGEOSERVER_DATA_DIR=${GEOSERVER_BASE} -DGEOWEBCACHE_CACHE_DIR=${GEOSERVER_BASE}/gwc_cache_dir -DGEOSERVER_LOG_LOCATION=${GEOSERVER_BASE}/logs/geoserver.log -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=${GEOSERVER_BASE}/memory_dumps -DALLOW_ENV_PARAMETRIZATION=true"
CATALINA_OPTS="$CATALINA_OPTS -Xbootclasspath/a:/tomcat/rtmpsGeoserver/webapps/geoserver/WEB-INF/lib/marlin-0.9.3-Unsafe.jar -Dsun.java2d.renderer=org.marlin.pisces.MarlinRenderingEngine"
export CATALINA_OPTS"

echo "${GEOSERVER_PROPERTES}" > /var/geoserver/datadir/geoserver-environment.properties
/bin/sed -i -e '/CATALINA_OPTS=/d' -e '/export CATALINA_OPTS/d' /usr/local/tomcat/conf/tomcat.conf
/bin/echo "${CATALINA_OPTS_GEO}" >>  /usr/local/tomcat/conf/tomcat.conf

set -m
catalina.sh run &
/usr/local/bin/geoserver-rest-config.sh
fg %1
