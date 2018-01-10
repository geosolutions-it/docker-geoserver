#!/bin/bash

if [ -z "$GEOSERVER_APP_NAME" ]; then
  echo "ERROR: $GEOSERVER_APP_NAME not defined or empty!"
  exit 1
fi

webapp_path="${CATALINA_BASE}/webapps/${GEOSERVER_APP_NAME}"

# not deployed? first run? unpack GeoServer WAR
if [ ! -d "$webapp_path" ]; then
    echo "GeoServer web application not found, unpacking WAR"
    if [ ! -f "${webapp_path}.war" ]; then
      echo "ERROR: ${webapp_path}.war not found!, exiting"
      exit 2
    else
      mkdir "$webapp_path" && unzip -q -o "${webapp_path}.war" -d "$webapp_path"
      if [ $? -ne 0 ]; then
        echo "ERROR: GeoServer WAR extraction failed!"
        exit 3
      fi
    fi
fi

# start Tomcat
cd "${CATALINA_BASE}/bin"
catalina.sh start
