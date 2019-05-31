#!/bin/bash

set -e

readonly ALL_PARAMETERS=$*

readonly GEOSERVER_BUILD_TYPE=${1}
readonly GEOSERVER_VERSION=${2}

readonly BASE_BUILD_URL="http://build.geoserver.org/geoserver"

readonly ARTIFACT_DIRECTORY=./resources
readonly ARTIFACT_DIRECTORY_GEOSERVER=${ARTIFACT_DIRECTORY}/geoserver
readonly ARTIFACT_DIRECTORY_PLUGINS=${ARTIFACT_DIRECTORY}/geoserver-plugins
readonly ARTIFACT_DIRECTORY_TMP=${ARTIFACT_DIRECTORY}/tmp
readonly ARTIFACT_FILENAME="geoserver.war"

function help() {
	if [ "$#" -ne 2 ] ; then
		echo "Usage: $0 [geoserver version] [geoserver master version]";
		echo "";
		echo "[geoserver build type] :         use 'master' for the last version, 'release' for stable released version ( f.e. 2.14.3 or 2.15.0 ) or 'snapshot' for last snaphost version ( f.e. 2.15.x )";
		echo "[geoserver version]    :         geoserver version ( f.e. 2.14.3, 2.15.0, 2.15.x, 2.16.x ),";
        echo "                                 if geoserver build type set to 'master' then geoserver version should be set to the next release numerical value ( f.e. 2.16.x if there is no 2.16.0 yet )";
		exit 1;	
	fi		
}

function clean_up_directory() {
	rm -rf ${1}/*
}

function extract_versions()  {
	IFS='.' SEMANTIC_VERSION=(${GEOSERVER_VERSION})
	unset IFS
    
    GEOSERVER_VERSION_MAJOR=${SEMANTIC_VERSION[0]}
	GEOSERVER_VERSION_MINOR=${SEMANTIC_VERSION[1]}
    GEOSERVER_VERSION_PATCH=${SEMANTIC_VERSION[2]}
    GEOSERVER_VERSION_MAIN=${GEOSERVER_VERSION_MAJOR}.${GEOSERVER_VERSION_MINOR}
}

function download_from_url_to_a_filepath {
	URL=${1}
	FILE_PATH=${2}
	FILE_DOWNLOADED=$(basename "${FILE_PATH}" )
	if [ -f "${FILE_PATH}" ]; then
		rm -f "${FILE_PATH}"
	fi	
	if [ ! -f "${FILE_PATH}" ]; then
		echo "* ${FILE_DOWNLOADED} artefact dowloading... *"
		curl -# -L -f "${URL}" -o "${FILE_PATH}"
		echo "* downloaded successfully *"
        echo ""
	else
		echo "* ${FILE_DOWNLOADED} artefact already dowloaded *"
	fi
}

function download_geoserver() {
    clean_up_directory ${ARTIFACT_DIRECTORY_GEOSERVER}
	extract_versions ${GEOSERVER_VERSION}

	if [ "${GEOSERVER_BUILD_TYPE}" == "master" ] && [ "${GEOSERVER_VERSION_PATCH}" == "x" ]; then
		local VERSION=${GEOSERVER_BUILD_TYPE}
		local GEOSERVER_FILE_NAME="geoserver-${VERSION}-latest-war.zip"
		local GEOSERVER_ARTIFACT_URL=${BASE_BUILD_URL}/${VERSION}/${GEOSERVER_FILE_NAME}
 
	elif [ "${GEOSERVER_BUILD_TYPE}" == "snapshot" ] && [ "${GEOSERVER_VERSION_PATCH}" == "x" ]; then
		local VERSION=${GEOSERVER_VERSION}
		local GEOSERVER_FILE_NAME="geoserver-${VERSION}-latest-war.zip"
		local GEOSERVER_ARTIFACT_URL=${BASE_BUILD_URL}/${VERSION}/${GEOSERVER_FILE_NAME}	

	elif [ "${GEOSERVER_BUILD_TYPE}" == "release" ] && [ "${GEOSERVER_VERSION_PATCH}" != "x" ]; then
		local VERSION=${GEOSERVER_VERSION}
		local GEOSERVER_FILE_NAME="geoserver-${VERSION}-war.zip"
		local GEOSERVER_ARTIFACT_URL=${BASE_BUILD_URL}/release/${VERSION}/${GEOSERVER_FILE_NAME}

    else
        echo "Wrong combination of build type and version."
        exit 1

	fi

    if [ -f /tmp/geoserver.war.zip ]; then
        rm /tmp/geoserver.war.zip
    fi
    if [ ! -e "${ARTIFACT_DIRECTORY_GEOSERVER}" ]; then
        mkdir -p "${ARTIFACT_DIRECTORY_GEOSERVER}"
    fi
    download_from_url_to_a_filepath  "${GEOSERVER_ARTIFACT_URL}" "/tmp/geoserver.war.zip"
    unzip -p /tmp/geoserver.war.zip ${ARTIFACT_FILENAME} > ${ARTIFACT_DIRECTORY_GEOSERVER}/${ARTIFACT_FILENAME}
}

function download_plugin()  {
	local TYPE=${1}
	local PLUGIN_NAME=${2}

	if [ "${GEOSERVER_BUILD_TYPE}" == "master" ] && [ "${GEOSERVER_VERSION_PATCH}" == "x" ]; then
		local PLUGIN_FULL_NAME=geoserver-${GEOSERVER_VERSION_MAIN}-SNAPSHOT-${PLUGIN_NAME}-plugin.zip
		local PLUGIN_ARTIFACT_URL=${BASE_BUILD_URL}/${GEOSERVER_BUILD_TYPE}/${TYPE}-latest/${PLUGIN_FULL_NAME}

	elif [ "${GEOSERVER_BUILD_TYPE}" == "snapshot" ] && [ "${GEOSERVER_VERSION_PATCH}" == "x" ]; then
		local GEOSERVER_VERSION_PLUGINS=${GEOSERVER_VERSION}
		local PLUGIN_FULL_NAME=geoserver-${GEOSERVER_VERSION_MAIN}-SNAPSHOT-${PLUGIN_NAME}-plugin.zip
		local PLUGIN_ARTIFACT_URL=${BASE_BUILD_URL}/${GEOSERVER_VERSION_PLUGINS}/${TYPE}-latest/${PLUGIN_FULL_NAME}
		
	elif [ "${GEOSERVER_BUILD_TYPE}" == "release" ] && [ "${GEOSERVER_VERSION_PATCH}" != "x" ]; then
		local GEOSERVER_VERSION_PLUGINS=${GEOSERVER_VERSION_MAIN}.x
        local PLUGIN_FULL_NAME=geoserver-${GEOSERVER_VERSION_MAIN}-SNAPSHOT-${PLUGIN_NAME}-plugin.zip
		local PLUGIN_ARTIFACT_URL=${BASE_BUILD_URL}/${GEOSERVER_VERSION_PLUGINS}/${TYPE}-latest/${PLUGIN_FULL_NAME}

    else
        echo "Wrong combination of build type and version."
        exit 1

	fi

    download_from_url_to_a_filepath "${PLUGIN_ARTIFACT_URL}" "${ARTIFACT_DIRECTORY_PLUGINS}/${PLUGIN_FULL_NAME}"
}

function build_artifact() {
    clean_up_directory ${ARTIFACT_DIRECTORY_TMP}

	unzip -q -o ${ARTIFACT_DIRECTORY_GEOSERVER}/${ARTIFACT_FILENAME}  -d ${ARTIFACT_DIRECTORY_TMP}
	
	for f in ${ARTIFACT_DIRECTORY_PLUGINS}/*; do
		unzip -q -o ${f} -d ${ARTIFACT_DIRECTORY_TMP}/WEB-INF/lib/
	done

    echo "* packing artifact file ... *"

    clean_up_directory ${ARTIFACT_DIRECTORY_GEOSERVER}
    cd ${ARTIFACT_DIRECTORY_GEOSERVER} && ARTIFACT_DIRECTORY_PATH=`pwd -P` && cd - > /dev/null 2>&1
	cd ${ARTIFACT_DIRECTORY_TMP} && zip -r "${ARTIFACT_DIRECTORY_PATH}"/${ARTIFACT_FILENAME} ./* > /dev/null 2>&1 && cd - > /dev/null 2>&1

    echo ""
	echo "Packed GeoServer .war file located in ${ARTIFACT_DIRECTORY_GEOSERVER} folder"
    if hash md5sum 2>/dev/null; then
        echo "New GeoServer .war file MD5 sum is: $(md5sum ${ARTIFACT_DIRECTORY_GEOSERVER}/${ARTIFACT_FILENAME})"
    fi
}

function main {
    help ${ALL_PARAMETERS}

    extract_versions

    download_geoserver

    clean_up_directory ${ARTIFACT_DIRECTORY_PLUGINS}
    download_plugin ext control-flow
#    download_plugin ext geofence
    download_plugin ext geofence-server
    download_plugin ext libjpeg-turbo
    download_plugin ext monitor
    download_plugin ext querylayer
    download_plugin ext wps
#    download_plugin ext css
    download_plugin community authkey
    download_plugin community status-monitoring
    download_plugin community wmts-multi-dimensional

    build_artifact
}

main
