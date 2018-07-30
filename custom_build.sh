#!/bin/bash

#set -x
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
readonly ARTIFACT_DIRECTORY=./resources
readonly GEOSERVER_ARTIFACT_DIRECTORY=${ARTIFACT_DIRECTORY}/geoserver/
readonly DATADIR_ARTIFACT_DIRECTORY=${ARTIFACT_DIRECTORY}/geoserver-datadir/
readonly PLUGIN_ARTIFACT_DIRECTORY=${ARTIFACT_DIRECTORY}/geoserver-plugins/

function help(){
	if [ "$#" -ne 8 ] ; then
		echo "Usage: $0 [docker image tag] [geoserver version] [geoserver master version] [github token] [github repository] [github repository owner] [datadir release number] [pull|no pull];"
		echo "";
		echo "[docker image tag] :          the tag to be used for the docker iamge ";
		echo "[geoserver version] :         the release version of geoserver to be used; you can set it to master if you want the last release";
		echo "[geoserver master version] :  if you use the master version for geoserver you need to set it to the numerical value for the next release;"
		echo "                              if you use a released version you need to put it to the release number";
		echo "[github token]:               token to access the Github API"; 
		echo "[github repository]:          Github repository name";     
		echo "[github repository owner]:    Github repository owner ";
		echo "[datadir release number]:     Github release number ";
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

function get_release_artifact_url_from_github() {
	REPO=${1}
    OWNER=${2}
    RELEASE=${3}
    local TEMP_FILE_PATH=/tmp/${RELEASE}
	GH_API="https://api.github.com"
	GH_REPO="$GH_API/repos/${OWNER}/${REPO}"
    GH_TARBALL="${GH_REPO}/tarball"
	declare -a HEADERS=("-H \"Authorization: token ${GITHUB_TOKEN}\"" '-H "Accept: application/vnd.github.v3.raw"')
    ENDPOINT="${GH_TARBALL}"

    PRE_ARTIFACT_URL="curl -L ${HEADERS[@]} -s ${ENDPOINT} --output ${TEMP_FILE_PATH}"
    RELEASE_ITEMS=$(eval $PRE_ARTIFACT_URL)
    tar xzvf "${TEMP_FILE_PATH}" --strip=1 -C "${DATADIR_ARTIFACT_DIRECTORY}"
}
 
function download_plugin()  {
	TYPE=${1}
	PLUGIN_NAME=${2}

	if  [[ "${GEOSERVER_VERSION}" == "master" ]]; then
		PLUGIN_FULL_NAME=geoserver-${GEOSERVER_MASTER_VERSION::-2}-SNAPSHOT-${PLUGIN_NAME}-plugin.zip
		local PLUGIN_ARTIFACT_URL=${BASE_BUILD_URL}/${GEOSERVER_VERSION}/${TYPE}-latest/${PLUGIN_FULL_NAME}
 
	else
		PLUGIN_FULL_NAME=geoserver-${GEOSERVER_VERSION::-2}-SNAPSHOT-${PLUGIN_NAME}-plugin.zip
		local PLUGIN_ARTIFACT_URL=${BASE_BUILD_URL}/${GEOSERVER_VERSION}/${TYPE}-latest/${PLUGIN_FULL_NAME}

	fi

    download_from_url_to_a_filepath "${PLUGIN_ARTIFACT_URL}" "${PLUGIN_ARTIFACT_DIRECTORY}${PLUGIN_FULL_NAME}"
}

function download_geoserver() {
	clean_up_directory ${GEOSERVER_ARTIFACT_DIRECTORY}
	local VERSION=${1}
	local GEOSERVER_FILE_NAME="geoserver-${VERSION}-latest-war.zip"
	local GEOSERVER_ARTIFACT_URL=${BASE_BUILD_URL}/${VERSION}/${GEOSERVER_FILE_NAME}
	if [ -f /tmp/geoserver.war.zip ]; then
		rm /tmp/geoserver.war.zip
	fi
	download_from_url_to_a_filepath  "${GEOSERVER_ARTIFACT_URL}" "/tmp/geoserver.war.zip"
    unzip -p /tmp/geoserver.war.zip geoserver.war > ${GEOSERVER_ARTIFACT_DIRECTORY}/geoserver.war
}


function build_with_data_dir() {

	local TAG=${1}

	docker build --no-cache \
		--build-arg BASE_IMAGE_NAME=gs-base \
		--build-arg BASE_IMAGE_TAG=7.0-jre8 \
		--build-arg INCLUDE_DATA_DIR=true \
		--build-arg INCLUDE_GS_WAR=true \
		--build-arg INCLUDE_PLUGINS=true \
		--build-arg GEOSERVER_APP_NAME=geoserver \
		-t geosolutionsit/geoserver:maps-"${TAG}" \
		 .
}

function build_without_data_dir() {

	local TAG=${1}
	local PULL_ENABLED=${2}
	if [[ "${PULL_ENABLED}" == "pull" ]]; then
		DOCKER_BUILD_COMMAND="docker build --pull"
	else
		DOCKER_BUILD_COMMAND="docker build"
	fi;	
	${DOCKER_BUILD_COMMAND} --no-cache \
		--build-arg BASE_IMAGE_NAME=gs-base \
		--build-arg BASE_IMAGE_TAG=7.0-jre8 \
		--build-arg INCLUDE_DATA_DIR=false \
		--build-arg INCLUDE_GS_WAR=true \
		--build-arg INCLUDE_PLUGINS=true \
		--build-arg GEOSERVER_APP_NAME=geoserver \
		-t geosolutionsit/geoserver:maps-"${TAG}"-dev \
		 .
}



function main {
    help ${ALL_PARAMETERS}
	download_geoserver "${GEOSERVER_VERSION}"
	clean_up_directory ${PLUGIN_ARTIFACT_DIRECTORY}
	download_plugin ext feature-pregeneralized 
	download_plugin ext css
	download_plugin community status-monitoring
	download_plugin ext monitor
	if  [[ ${GEOSERVER_DATA_DIR_RELEASE} = "dev" ]]; then
   	    build_without_data_dir "${TAG}" "${PULL}"
   	else
   		clean_up_directory ${DATADIR_ARTIFACT_DIRECTORY}
		get_release_artifact_url_from_github "${GITHUB_REPO}" "${GITHUB_REPO_OWNER}" "${GEOSERVER_DATA_DIR_RELEASE}"
 		build_with_data_dir "${TAG}" "${PULL}"
   	fi
}

main
