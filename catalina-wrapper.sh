#!/bin/bash

until PGPASSWORD="$POSTGRES_PASSWORD" psql -h "$POSTGRES_ENDPOINT" -U "$POSTGRES_USER" -d "$OSM_DB" -c '\q'; do
  >&2 echo "Postgres is unavailable - sleeping"
  sleep 1
done

# update sld files modification date to speed up GS startup
touch ${GEOSERVER_DATA_DIR}/styles/*sld

webapp_path="${CATALINA_BASE}/webapps/${GEOSERVER_APP_NAME}"

# not deployed? first run? unpack GeoServer WAR
if [ $GEOSERVER_APP_NAME != geoserver ]; then
  if [ ! -d "$webapp_path" ]; then
    echo "GeoServer web application not found, changing geoserver to ${GEOSERVER_APP_NAME}"
    mv ${CATALINA_BASE}/webapps/geoserver ${CATALINA_BASE}/webapps/${GEOSERVER_APP_NAME}
  fi
fi

# start Tomcat
cd "${CATALINA_BASE}/bin"
catalina.sh run
