#!/bin/bash

set -e

TAG=${1}
readonly GEOSERVER_VERSION=${2}
readonly GEOSERVER_MASTER_VERSION=${3}
readonly GITHUB_TOKEN=${4}
readonly GITHUB_REPO=${5} 
readonly GITHUB_REPO_OWNER=${6} 
readonly GEOSERVER_DATA_DIR_RELEASE=${7}
readonly PULL=${8}
readonly ALL_PARAMETERS=$*


readonly BASE_BUILD_URL="https://build.geoserver.org/geoserver/"
readonly EXTRA_FONTS_URL="https://www.dropbox.com/s/hs5743lwf1rktws/fonts.tar.gz?dl=1"
readonly MARLIN_VERSION=0.9.2
readonly ARTIFACT_DIRECTORY=./resources
readonly GEOSERVER_ARTIFACT_DIRECTORY=${ARTIFACT_DIRECTORY}/geoserver/
readonly DATADIR_ARTIFACT_DIRECTORY=${ARTIFACT_DIRECTORY}/geoserver-datadir/
readonly PLUGIN_ARTIFACT_DIRECTORY=${ARTIFACT_DIRECTORY}/geoserver-plugins/
readonly FONTS_ARTIFACT_DIRECTORY=${ARTIFACT_DIRECTORY}/fonts/
readonly MARLIN_ARTIFACT_DIRECTORY=${ARTIFACT_DIRECTORY}/marlin/
readonly GS_WAR_NAME="geoserver.war"

export DATADIR_ARTIFACT_DIRECTORY
export GEOSERVER_DATA_DIR_RELEASE
export GITHUB_TOKEN
export GITHUB_REPO
export GITHUB_REPO_OWNER

function help() {
	if [ "$#" -ne 8 ] ; then
		echo "Usage: $0 [docker image tag] [geoserver version] [geoserver master version] [github token] [github repository] [github repository owner] [datadir release number] [pull|no pull]";
		echo "";
		echo "[docker image tag] :          the tag to be used for the docker iamge ";
		echo "[geoserver version] :         the release version of geoserver to be used ( f.e. 2.15.0 ) or last snaphost version ( f.e. 2.15.x ); also you can set it to 'master' if you want the last release";
		echo "[geoserver master version] :  if you use the master version for geoserver you need to set it to the numerical value for the next release ( f.e. 2.16.x )";
		echo "                              if you use a released version you need to put it to the release number ( f.e. 2.15.x )";
		echo "[github token]:               token to access the Github API"; 
		echo "[github repository]:          Github repository name";     
		echo "[github repository owner]:    Github repository owner ";
		echo "[datadir release number]:     Github release number; if this parameter is equal to 'dev' the datadir is not burned in the docker images; if this parameter is equal to 'war' then files packed into .war package";
		echo "[pull|no pull]:               docker build use always a remote image or a local image";
		exit 1;	
	fi		
}

function clean_up_directory() {
	rm -rf ${1}/*
}

function download_from_url_to_a_filepath {
	URL=${1}
	FILE_PATH=${2}
	FILE_DOWNLOADED=$(basename "${FILE_PATH}" )
	if [ -f "${FILE_PATH}" ]; then
		rm -f "${FILE_PATH}"
	fi	
	if [ ! -f "${FILE_PATH}" ]; then
		curl -L "${URL}" --output "${FILE_PATH}"
		echo "* ${FILE_DOWNLOADED} artefact dowloaded *"
	else
		echo "* ${FILE_DOWNLOADED} artefact already dowloaded *"
	fi
}

function extract_versions()  {
	IFS='.'
	SEMANTIC_VERSION=(${1})
	IFS=' '
	GEOSERVER_VERSION_MAJOR=${SEMANTIC_VERSION[0]}.${SEMANTIC_VERSION[1]}
	GEOSERVER_VERSION_MINOR=${SEMANTIC_VERSION[2]}
}

function download_plugin()  {
	TYPE=${1}
	PLUGIN_NAME=${2}

	extract_versions ${GEOSERVER_VERSION}

	if  [[ "${GEOSERVER_VERSION}" == "master" ]]; then
		extract_versions ${GEOSERVER_MASTER_VERSION}
		PLUGIN_FULL_NAME=geoserver-${GEOSERVER_VERSION_MAJOR}-SNAPSHOT-${PLUGIN_NAME}-plugin.zip
		local PLUGIN_ARTIFACT_URL=${BASE_BUILD_URL}/${GEOSERVER_VERSION}/${TYPE}-latest/${PLUGIN_FULL_NAME}

	elif [ "${GEOSERVER_VERSION_MINOR}" == "x" ]; then
		PLUGIN_FULL_NAME=geoserver-${GEOSERVER_VERSION_MAJOR}-SNAPSHOT-${PLUGIN_NAME}-plugin.zip
		local PLUGIN_ARTIFACT_URL=${BASE_BUILD_URL}/${GEOSERVER_VERSION}/${TYPE}-latest/${PLUGIN_FULL_NAME}
		
	else
		PLUGIN_FULL_NAME=geoserver-${GEOSERVER_VERSION_MAJOR}-SNAPSHOT-${PLUGIN_NAME}-plugin.zip
		local PLUGIN_ARTIFACT_URL=${BASE_BUILD_URL}/${GEOSERVER_MASTER_VERSION}/${TYPE}-latest/${PLUGIN_FULL_NAME}

	fi

    if [ ! -e "${PLUGIN_ARTIFACT_URL}" ]; then
        mkdir -p "${PLUGIN_ARTIFACT_URL}"
    fi

    download_from_url_to_a_filepath "${PLUGIN_ARTIFACT_URL}" "${PLUGIN_ARTIFACT_DIRECTORY}${PLUGIN_FULL_NAME}"
}

function download_fonts()  {
    if [ ! -e "${FONTS_ARTIFACT_DIRECTORY}" ]; then
        mkdir -p "${FONTS_ARTIFACT_DIRECTORY}"
    fi
    download_from_url_to_a_filepath "${EXTRA_FONTS_URL}" "${FONTS_ARTIFACT_DIRECTORY}/fonts.tar.gz"
}

function download_marlin()  {
    IFS='.' read -r -a marlin_v_arr <<< "$MARLIN_VERSION"
    unset IFS

    marlin_major=${marlin_v_arr[0]}
    marlin_minor=${marlin_v_arr[1]}
    marlin_patch=${marlin_v_arr[2]}

    if [ ! -e "${MARLIN_ARTIFACT_DIRECTORY}" ]; then
        mkdir -p "${MARLIN_ARTIFACT_DIRECTORY}"
    fi

    marlin_url_1="https://github.com/bourgesl/marlin-renderer/releases/download/v${marlin_major}_${marlin_minor}_${marlin_patch}/marlin-${marlin_major}.${marlin_minor}.${marlin_patch}-Unsafe.jar"
    marlin_url_2="https://github.com/bourgesl/marlin-renderer/releases/download/v${marlin_major}_${marlin_minor}_${marlin_patch}/marlin-${marlin_major}.${marlin_minor}.${marlin_patch}-Unsafe-sun-java2d.jar"
    download_from_url_to_a_filepath "${marlin_url_1}" "${MARLIN_ARTIFACT_DIRECTORY}/marlin-${marlin_major}.${marlin_minor}.${marlin_patch}-Unsafe.jar"
    download_from_url_to_a_filepath "${marlin_url_2}" "${MARLIN_ARTIFACT_DIRECTORY}/marlin-${marlin_major}.${marlin_minor}.${marlin_patch}-Unsafe-sun-java2d.jar"
}

function download_geoserver() {
    clean_up_directory ${GEOSERVER_ARTIFACT_DIRECTORY}
	extract_versions ${1}

	if  [[ "${GEOSERVER_VERSION}" == "master" ]]; then
		local VERSION=${1}
		local GEOSERVER_FILE_NAME="geoserver-${VERSION}-latest-war.zip"
		local GEOSERVER_ARTIFACT_URL=${BASE_BUILD_URL}${VERSION}/${GEOSERVER_FILE_NAME}
 
	elif [ "${GEOSERVER_VERSION_MINOR}" == "x" ]; then
		local VERSION=${1}
		local GEOSERVER_FILE_NAME="geoserver-${GEOSERVER_VERSION_MAJOR}.${GEOSERVER_VERSION_MINOR}-latest-war.zip"
		local GEOSERVER_ARTIFACT_URL=${BASE_BUILD_URL}${GEOSERVER_VERSION_MAJOR}.${GEOSERVER_VERSION_MINOR}/${GEOSERVER_FILE_NAME}	

	else
		local VERSION=${1}
		local GEOSERVER_FILE_NAME="geoserver-${VERSION}-war.zip"
		local GEOSERVER_ARTIFACT_URL=${BASE_BUILD_URL}release/${VERSION}/${GEOSERVER_FILE_NAME}

	fi

    if [ -f /tmp/geoserver.war.zip ]; then
        rm /tmp/geoserver.war.zip
    fi
    if [ ! -e "${GEOSERVER_ARTIFACT_DIRECTORY}" ]; then
        mkdir -p "${GEOSERVER_ARTIFACT_DIRECTORY}"
    fi
    download_from_url_to_a_filepath  "${GEOSERVER_ARTIFACT_URL}" "/tmp/geoserver.war.zip"
    unzip -p /tmp/geoserver.war.zip geoserver.war > ${GEOSERVER_ARTIFACT_DIRECTORY}/geoserver.war
}

function build_war_file() {
	unzip -q -o ${GEOSERVER_ARTIFACT_DIRECTORY}geoserver.war  -d ${ARTIFACT_DIRECTORY}/tmp
	
	for f in ${PLUGIN_ARTIFACT_DIRECTORY}*; do
		unzip -q -o ${f} -d ${ARTIFACT_DIRECTORY}/tmp/WEB-INF/lib/
	done

	zip -r ${ARTIFACT_DIRECTORY}/build/${GS_WAR_NAME} ${ARTIFACT_DIRECTORY}/tmp/*

	echo "Packed GeoServer .war file located in ./build folder"
}

function main {
    help ${ALL_PARAMETERS}
	clean_up_directory ${GEOSERVER_ARTIFACT_DIRECTORY}
    download_geoserver "${GEOSERVER_VERSION}"
    clean_up_directory ${PLUGIN_ARTIFACT_DIRECTORY}
    download_plugin ext control-flow
    download_plugin ext geofence
    download_plugin ext geofence-server
    download_plugin ext libjpeg-turbo
    download_plugin ext monitor
    download_plugin ext querylayer
    download_plugin ext wps
    download_plugin community authkey
    download_plugin community status-monitoring
    download_plugin community wmts-multi-dimensional
    download_marlin

	if  [[ ${GEOSERVER_DATA_DIR_RELEASE} = "war" ]]; then
		clean_up_directory ${ARTIFACT_DIRECTORY}/tmp
		clean_up_directory ${ARTIFACT_DIRECTORY}/build
		build_war_file

	elif  [[ ${GEOSERVER_DATA_DIR_RELEASE} = "dev" ]]; then
   	    ./docker_build.sh "build_without_data_dir" "${TAG}" "${PULL}"
   	else
		clean_up_directory ${DATADIR_ARTIFACT_DIRECTORY}
		./docker_build.sh "build_with_data_dir" "${TAG}" "${PULL}"
   	fi
}

main
