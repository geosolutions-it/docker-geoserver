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

add_web_xml_constraints() {
  WEB_XML="$1"
  if grep --quiet 'BlockDemoRequests' "$WEB_XML"; then
    printf "INFO: web.xml constraints already in place (%s)\n" "$WEB_XML"
    return
  fi

  printf "INFO: adding constraints to web.xml (%s)\n" "$WEB_XML"

  PATCH="    <security-constraint>
        <web-resource-collection>
            <web-resource-name>BlockDemoRequests</web-resource-name>
            <url-pattern>/TestWfsPost/*</url-pattern>
        </web-resource-collection>
        <auth-constraint>
            <role-name>BLOCKED</role-name>
        </auth-constraint>
    </security-constraint>
    <security-constraint>
        <web-resource-collection>
            <web-resource-name>BlockGWC</web-resource-name>
            <url-pattern>/gwc/*</url-pattern>
        </web-resource-collection>
        <auth-constraint>
            <role-name>BLOCKED</role-name>
        </auth-constraint>
    </security-constraint>
    <security-constraint>
        <web-resource-collection>
            <web-resource-name>AllowGWC_Demo</web-resource-name>
            <url-pattern>/gwc/demo/*</url-pattern>
        </web-resource-collection>
    </security-constraint>
    <security-constraint>
        <web-resource-collection>
            <web-resource-name>AllowGWC_Services</web-resource-name>
            <url-pattern>/gwc/service/*</url-pattern>
        </web-resource-collection>
    </security-constraint>
    <security-constraint>
        <web-resource-collection>
            <web-resource-name>AllowGWC_Rest</web-resource-name>
            <url-pattern>/gwc/rest/*</url-pattern>
        </web-resource-collection>
    </security-constraint>"


  awk -v block="$PATCH" '
  /<\/web-app>/ {
    print block
  }
  { print }
  ' "$WEB_XML" \
    > "$CATALINA_HOME"/webapps/"${GEOSERVER_APP_NAME}"/WEB-INF/web_patched.xml

  # Using cp instead of mv to copy file data instead of renaming the file.
  # Useful to preserve the inode in case of externalized file.
  cp "$CATALINA_HOME"/webapps/"${GEOSERVER_APP_NAME}"/WEB-INF/web_patched.xml \
    "$WEB_XML"
  rm "$CATALINA_HOME"/webapps/"${GEOSERVER_APP_NAME}"/WEB-INF/web_patched.xml
}


try_set_config_xml_filter_rest() {
  CONFIG_XML="$1"
  if grep --quiet '<filters name="rest" class="org.geoserver.security.ServiceLoginFilterChain".*path="/rest\.\*,/rest/\*\*"' "$CONFIG_XML"; then
    printf "INFO: config.xml rest filter already updated (%s)\n" "$CONFIG_XML"
    return
  fi

  printf "INFO: updating rest filter (%s)\n" "$CONFIG_XML"

  TEMP_FILE="$(mktemp)"
  cp "$CONFIG_XML" "$TEMP_FILE"

  sed -ire 's|\(<filters name="rest" class="org.geoserver.security.ServiceLoginFilterChain".*\)path="[^"]*"|\1path="/rest.*,/rest/**"|' "$TEMP_FILE"

  cp "$TEMP_FILE" "$CONFIG_XML"
  rm -rf "$TEMP_FILE"
}

try_set_config_xml_filter_gwc() {
  CONFIG_XML="$1"
  if grep --quiet '<filters name="gwc" class="org.geoserver.security.ServiceLoginFilterChain".*path="/gwc/rest\.\*,/gwc/rest/\*\*"' "$CONFIG_XML"; then
    printf "INFO: config.xml gwc filter already updated (%s)\n" "$CONFIG_XML"
    return
  fi

  printf "INFO: updating gwc filter (%s)\n" "$CONFIG_XML"

  TEMP_FILE="$(mktemp)"
  cp "$CONFIG_XML" "$TEMP_FILE"

  sed -ire 's|\(<filters name="gwc" class="org.geoserver.security.ServiceLoginFilterChain".*\)path="[^"]*"|\1path="/gwc/rest.*,/gwc/rest/**"|' "$TEMP_FILE"

  cp "$TEMP_FILE" "$CONFIG_XML"
  rm -rf "$TEMP_FILE"
}

GS_CORE_JAR_PATH="$(find "$CATALINA_HOME"/webapps/"${GEOSERVER_APP_NAME}"/WEB-INF/lib -name 'gs-web-core*.jar')"
GS_CORE_JAR="$(basename "$GS_CORE_JAR_PATH")"
case "$GS_CORE_JAR" in
*-2.25* | *-2.26*)
  WEB_XML="$CATALINA_HOME"/webapps/"${GEOSERVER_APP_NAME}"/WEB-INF/web.xml
  CONFIG_XML="$GEOSERVER_DATA_DIR"/security/config.xml

  printf "INFO: GeoServer 2.25 or 2.26 (from %s)\n" "$GS_CORE_JAR"
  add_web_xml_constraints "$WEB_XML"
  try_set_config_xml_filter_rest "$CONFIG_XML"
  try_set_config_xml_filter_gwc "$CONFIG_XML"
  ;;

*)
  printf "INFO: GeoServer version (from %s) does not require updating web.xml\n" "$GS_CORE_JAR"
  ;;
esac

# start Tomcat
cd "${CATALINA_BASE}/bin"
catalina.sh run

