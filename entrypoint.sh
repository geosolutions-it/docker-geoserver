#!/usr/bin/env bash
geoserver-plugin-download.sh ${CATALINA_BASE}/webapps/${APP_LOCATION}/WEB-INF/lib $PLUGIN_DYNAMIC_URLS
set -m

# FIXME: this workaround (for a deploy in a Swarm) keeps GS from starting and
# crashing, because of JDBC not being able to connect to Postgres
db_err=6
while [ $db_err -eq 6 ]; do
  curl -sS "$DATABASE_HOST"
  db_err=$?
  sleep 1
done

catalina.sh run &
/usr/local/bin/geoserver-rest-config.sh
fg %1
