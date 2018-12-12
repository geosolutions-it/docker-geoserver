#!/bin/bash

until PGPASSWORD="$POSTGRES_PASSWORD" psql -h "$POSTGRES_ENDPOINT" -U "$POSTGRES_USER" -d "$POSTGRES_DBNAME" -c '\q'; do
  >&2 echo "Postgres is unavailable - sleeping"
  sleep 1
done

if [ -z "$GEOSERVER_APP_NAME" ]; then
  echo "ERROR: $GEOSERVER_APP_NAME not defined or empty!"
  exit 1
fi

# update sld files modification date to speed up GS startup
touch ${GEOSERVER_DATA_DIR}/styles/*sld

webapp_path="${CATALINA_BASE}/webapps/${GEOSERVER_APP_NAME}"

# not deployed? first run? unpack GeoServer WAR
if [ ! -d "$webapp_path" ]; then
    echo "GeoServer web application not found, unpacking WAR"
    if [ -f "${webapp_path}.war" ];then
      war_path="${webapp_path}.war"
    elif [ -f "${CATALINA_BASE}/webapps/geoserver.war" ]; then
      war_path="${CATALINA_BASE}/webapps/geoserver.war"
    else
      echo "ERROR: ${webapp_path}.war not found!, exiting"
      exit 2
    fi
    mkdir "$webapp_path" && unzip -q -o "$war_path" -d "$webapp_path" && rm -f "$war_path"
    if [ $? -ne 0 ]; then
      echo "ERROR: GeoServer WAR extraction failed!"
      exit 3
    fi
fi

# start Tomcat
cd "${CATALINA_BASE}/bin"
catalina.sh run
