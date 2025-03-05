#!/bin/bash

OUTPUT_DESTINATION=/tmp/probe.war
if [ -z "${PROBE_VERSION}" ]; then
  PROBE_VERSION=4.1.0
fi

if [ -z "${PROBE_URL}" ]; then
  PROBE_URL=https://github.com/psi-probe/psi-probe/releases/download/psi-probe-${PROBE_VERSION}/probe.war
fi

if [ -z "${PROBE_CONTEXT_ROOT}" ]; then
  PROBE_CONTEXT_ROOT=probe

fi

curl --progress-bar -fLvo "${OUTPUT_DESTINATION}" "${PROBE_URL}" || exit 1

# Setup tomcat users xml
if [ -z "${TOMCAT_USER}" ]; then
  TOMCAT_USER="tomcat"
fi

if [ -z "${TOMCAT_PASSWORD}" ]; then
  TOMCAT_PASSWORD="tomcat_pass"
fi


cat > "${CATALINA_HOME}"/conf/tomcat-users.xml <<EOF
<?xml version="1.0" encoding="UTF-8"?>

<tomcat-users xmlns="http://tomcat.apache.org/xml"
              xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
              xsi:schemaLocation="http://tomcat.apache.org/xml tomcat-users.xsd"
              version="1.0">

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


# Deploy Application

unzip -o ${OUTPUT_DESTINATION} -d "${CATALINA_HOME}"/webapps/"${PROBE_CONTEXT_ROOT}"

