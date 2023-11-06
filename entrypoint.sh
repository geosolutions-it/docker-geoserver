#!/usr/bin/env bash
geoserver-plugin-download.sh ${CATALINA_BASE}/webapps/${APP_LOCATION}/WEB-INF/lib $PLUGIN_DYNAMIC_URLS
set -m

# FIXME: this workaround (for a deploy in a Swarm) keeps GS from starting and
# crashing, because of JDBC not being able to connect to Postgres
attempts=0
while ! /usr/bin/pg_isready -h "$DATABASE_HOST"; do
  attempts=$((attempts + 1))
  printf "Checking database availability: attempt %s\n" "$attempts"
  sleep 1
done

catalina.sh run &
/usr/local/bin/geoserver-rest-config.sh
fg %1
