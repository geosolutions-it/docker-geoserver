#!/bin/bash

set -x
set -e
TAG=${1}
readonly GEOSERVER_VERSION=${2}
readonly GEOSERVER_MASTER_VERSION=${3}
readonly GITHUB_TOKEN=${4}
readonly GITHUB_REPO=${5} 
readonly GITHUB_REPO_OWNER=${6} 
readonly GEOSERVER_DATA_DIR_RELEASE=${7}



readonly BASE_BUILD_URL="https://build.geoserver.org/geoserver/"
readonly ARTIFACT_DIRECTORY=./resources
readonly GEOSERVER_ARTIFACT_DIRECTORY=${ARTIFACT_DIRECTORY}/geoserver/
readonly DATADIR_ARTIFACT_DIRECTORY=${ARTIFACT_DIRECTORY}/geoserver-datadir/
readonly PLUGIN_ARTIFACT_DIRECTORY=${ARTIFACT_DIRECTORY}/geoserver-plugins/


function clean_up_directory() {
	rm -rf ${1}/*
}

function download_from_url_to_a_filepath {
	URL=${1}
	FILE_PATH=${2}
	FILE_DOWNLOADED=$(basename "${FILE_PATH}" )
	if [ ! -f "${FILE_PATH}" ]; then
		curl -L "${URL}" --output "${FILE_PATH}"
		echo "* ${FILE_DOWNLOADED} artefact dowloaded *"
	else
		echo "* ${FILE_DOWNLOADED} artefact already dowloaded *"
	fi
}

#84b846c95ffac2ef93c635e0657c9d46eead4ed1
#https://codeload.github.com/geosolutions-it/anaximander/tar.gz/0.1?token=Ai5866Ah_GED_tUtRbtf7NLLSGN6HMI0ks5bUI8FwA==
#curl -H "Authorization: token $GITHUB_TOKEN" -H "Accept: application/vnd.github.v3.raw"  -s https://api.github.com/repos/$REPO/releases | jq ". | map(select(.tag_name == \"$VERSION\"))[0].tarball_url"
#curl -L -H "Authorization: token $GITHUB_TOKEN"  https://api.github.com/repos/geosolutions-it/anaximander/tarball/0.1 -o /tmp/pippo


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


 #    declare -a filter=("| jq \"." "| map(select(.tag_name == $RELEASE))[0].tarball_url\"" )
 #    echo "${filter[@]}"
 #    ARTIFACT_URL="echo \"${RELEASE_ITEMS}\" ${filter[@]}"
 #    echo -e
	# echo $ARTIFACT_URL
	# echo -e
 #   	eval $ARTIFACT_URL

   # echo $ciccio
   # echo $ciccio | jq ". | map(select(.tag_name == \"$RELEASE\"))[0].tarball_url"
   #ARFIFACT_URL=$(curl "${HEADERS}" -s "${ENDPOINT}"| jq ". | map(select(.tag_name == \"${RELEASE}\"))[0].tarball_url") 

}
 


# function get_datadir() {
# 	# local GEOSERVER_DATA_DIR_REPOSITORY=${1}
#  #    local GEOSERVER_DATA_DIR_RELEASE=${2}
#     local TEMP_FILE_PATH=/tmp/${GEOSERVER_DATA_DIR_RELEASE}
# 	local URL="${GEOSERVER_DATA_DIR_REPOSITORY}"/"${GEOSERVER_DATA_DIR_RELEASE}"?token="${GITHUB_TOKEN}"
# 	echo $URL
# 	download_from_url_to_a_filepath "${URL}" "${TEMP_FILE_PATH}"
# 	tar xzvf "${TEMP_FILE_PATH}" --strip=1 -C "${DATADIR_ARTIFACT_DIRECTORY}"
# }


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

	docker build --no-cache \
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
    
	download_geoserver "${GEOSERVER_VERSION}"
	clean_up_directory ${PLUGIN_ARTIFACT_DIRECTORY}
	download_plugin ext feature-pregeneralized 
	download_plugin ext css
	if  [[ ${GEOSERVER_DATA_DIR_RELEASE} = "dev" ]]; then
   	    build_without_data_dir "${TAG}"
   else
   		clean_up_directory ${DATADIR_ARTIFACT_DIRECTORY}
		get_release_artifact_url_from_github "${GITHUB_REPO}" "${GITHUB_REPO_OWNER}" "${GEOSERVER_DATA_DIR_RELEASE}"
 		build_with_data_dir "${TAG}"
   fi
}

main
