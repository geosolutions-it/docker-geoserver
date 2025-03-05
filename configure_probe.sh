#!/bin/bash

PROBE_URL_PATH=$1

echo "The probe URL is, "${PROBE_URL_PATH}""

OUTPUT_DESTINATION=/tmp/probe.war

if [ -n "${PROBE_URL_PATH}" ]; then
  if [[ "${PROBE_URL_PATH}" =~ ^http ]]; then
    curl --progress-bar -fLvo "${OUTPUT_DESTINATION}" "${PROBE_URL_PATH}" || exit 1
  else
    # it's a local file so we copy to destination
    cp -v "${PROBE_URL_PATH}" "${OUTPUT_DESTINATION}" || exit 1
  fi
else
  echo "$PROBE_URL_PATH is not set"
  exit 1
fi


# Deploy Application

unzip -o ${OUTPUT_DESTINATION} -d "${CATALINA_HOME}"/webapps/"${PROBE_CONTEXT_ROOT}"

