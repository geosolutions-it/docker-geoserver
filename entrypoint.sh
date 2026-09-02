#!/usr/bin/env bash
geoserver-plugin-download.sh ${CATALINA_BASE}/webapps/geoserver/WEB-INF/lib $PLUGIN_DYNAMIC_URLS
set -m
export CATALINA_OPTS="$CATALINA_OPTS $EXTRA_GEOSERVER_OPTS"

# Remove probe based on env var
if [ $ACTIVATE_PROBE = 'NO' ];then
  if [ -d "${CATALINA_HOME}"/webapps/"${PROBE_CONTEXT_ROOT}" ];then
    rm -rf "${CATALINA_HOME}"/webapps/"${PROBE_CONTEXT_ROOT}"
  fi
else
  if [ -z "${TOMCAT_USER}" ]; then
    TOMCAT_USER="tomcat"
  fi

  if [ -z "${TOMCAT_PASSWORD}" ]; then
    PASSWORD=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | fold -w 15 | head -n 1)
    # We need a way to report this password for a user in logs or we assume he needs to view tomcat_users.xml
    TOMCAT_PASSWORD=${PASSWORD}
  fi

  # Use Sed to set the tomcat users.xml

  sed -i '$d' "${CATALINA_HOME}"/conf/tomcat-users.xml
  cat >> "${CATALINA_HOME}"/conf/tomcat-users.xml <<EOF
    <role rolename="admin-gui"/>
    <role rolename="admin-script"/>
    <role rolename="manager-gui"/>
    <role rolename="manager-status"/>
    <role rolename="manager-script"/>
    <role rolename="manager-jmx"/>
    <role rolename="probeuser" />
    <role rolename="poweruser" />
    <role rolename="poweruserplus" />
    <user username="${TOMCAT_USER}" password="${TOMCAT_PASSWORD}" roles="admin-gui,admin-script,manager-gui,manager-status,manager-script,manager-jmx"/>
  </tomcat-users>
EOF
fi



# Enable CORS (inspired by https://github.com/oscarfonts/docker-geoserver)
# if enabled, this will add the filter definitions
# to the end of the web.xml
# (this will only happen if our filter has not yet been added before)
if [ "${CORS_ENABLED}" = "true" ]; then
  if ! grep -q DockerGeoServerCorsFilter "$CATALINA_HOME/webapps/geoserver/WEB-INF/web.xml"; then
    echo "Enable CORS for $CATALINA_HOME/webapps/geoserver/WEB-INF/web.xml"

    # Add support for access-control-allow-credentials when the origin is not a wildcard when specified via env var
    if [ "${CORS_ALLOWED_ORIGINS}" != "*" ] && [ "${CORS_ALLOW_CREDENTIALS}" = "true" ]; then
      CORS_ALLOW_CREDENTIALS="true"
    else
      CORS_ALLOW_CREDENTIALS="false"
    fi

    sed -i "\:</web-app>:i\\
    <filter>\n\
      <filter-name>DockerGeoServerCorsFilter</filter-name>\n\
      <filter-class>org.apache.catalina.filters.CorsFilter</filter-class>\n\
      <init-param>\n\
          <param-name>cors.allowed.origins</param-name>\n\
          <param-value>${CORS_ALLOWED_ORIGINS}</param-value>\n\
      </init-param>\n\
      <init-param>\n\
          <param-name>cors.allowed.methods</param-name>\n\
          <param-value>${CORS_ALLOWED_METHODS}</param-value>\n\
      </init-param>\n\
      <init-param>\n\
        <param-name>cors.allowed.headers</param-name>\n\
        <param-value>${CORS_ALLOWED_HEADERS}</param-value>\n\
      </init-param>\n\
      <init-param>\n\
        <param-name>cors.support.credentials</param-name>\n\
        <param-value>${CORS_ALLOW_CREDENTIALS}</param-value>\n\
      </init-param>\n\
    </filter>\n\
    <filter-mapping>\n\
      <filter-name>DockerGeoServerCorsFilter</filter-name>\n\
      <url-pattern>/*</url-pattern>\n\
    </filter-mapping>" "$CATALINA_HOME/webapps/geoserver/WEB-INF/web.xml";
  fi
fi

# Disable tomcat version disclosure
sed -i '/<\/Host>/i\ \ \ \ \ \ \ \ <Valve className="org.apache.catalina.valves.ErrorReportValve" showReport="false" showServerInfo="false"/>' "$CATALINA_HOME/conf/server.xml";

# Custom webapp location
if [ -n "${APP_LOCATION}" ] && [ "${APP_LOCATION}" != "geoserver" ]; then
  mv "${CATALINA_BASE}"/webapps/geoserver "${CATALINA_BASE}"/webapps/"${APP_LOCATION}"
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
    > "$CATALINA_HOME"/webapps/"${APP_LOCATION}"/WEB-INF/web_patched.xml

  # Using cp instead of mv to copy file data instead of renaming the file.
  # Useful to preserve the inode in case of externalized file.
  cp "$CATALINA_HOME"/webapps/"${APP_LOCATION}"/WEB-INF/web_patched.xml \
    "$WEB_XML"
  rm "$CATALINA_HOME"/webapps/"${APP_LOCATION}"/WEB-INF/web_patched.xml
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

GS_CORE_JAR_PATH="$(find "$CATALINA_HOME"/webapps/"${APP_LOCATION}"/WEB-INF/lib -name 'gs-web-core*.jar')"
GS_CORE_JAR="$(basename "$GS_CORE_JAR_PATH")"
case "$GS_CORE_JAR" in
*-2.25* | *-2.26*)
  WEB_XML="$CATALINA_HOME"/webapps/"${APP_LOCATION}"/WEB-INF/web.xml
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

catalina.sh run &
/usr/local/bin/geoserver-rest-config.sh
fg %1
