#!/bin/bash

set -e

readonly ALL_PARAMETERS=$*

readonly TAG=${1}
readonly PULL=${2}

readonly GITHUB_TOKEN=${3}
readonly GITHUB_REPO=${4} 
readonly GITHUB_REPO_OWNER=${5}
readonly GEOSERVER_DATA_DIR_RELEASE=${6}
readonly INCLUDE_PLUGINS=true #${7}

readonly EXTRA_FONTS_URL="https://www.dropbox.com/s/hs5743lwf1rktws/fonts.tar.gz?dl=1"
readonly MARLIN_VERSION=0.9.2
readonly ARTIFACT_DIRECTORY=./resources
readonly ARTIFACT_DIRECTORY_DATADIR=${ARTIFACT_DIRECTORY}/geoserver-datadir/
readonly ARTIFACT_DIRECTORY_FONTS=${ARTIFACT_DIRECTORY}/fonts/
readonly ARTIFACT_DIRECTORY_MARLIN=${ARTIFACT_DIRECTORY}/marlin/

function help() {
	if [ "$#" -ne 7 ] ; then
		echo "Usage: $0 [docker image tag] [pull|nopull] [github token] [github repository] [github repository owner] [datadir release number] [include geoserver plugins]";
		echo "";
		echo "[docker image tag] :          the tag to be used for the docker iamge ";
		echo "[pull|no pull]:               docker build use always a remote image or a local image";
		echo "[github token]:               token to access the Github API";
		echo "[github repository]:          Github repository name";
		echo "[github repository owner]:    Github repository owner ";
		echo "[datadir release number]:     Github release number; if this parameter is equal to 'dev' the datadir is not burned in the docker images";
        echo "[include geoserver plugins]:  include GeoServer plugins into Docker image or not - true/false";
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
		echo "* ${FILE_DOWNLOADED} artefact dowloading... *"
		curl -# -L -f "${URL}" -o "${FILE_PATH}"
		echo "* downloaded successfully *"
        echo ""
	else
		echo "* ${FILE_DOWNLOADED} artefact already dowloaded *"
	fi
}

function download_fonts()  {
    if [ ! -e "${ARTIFACT_DIRECTORY_FONTS}" ]; then
        mkdir -p "${ARTIFACT_DIRECTORY_FONTS}"
    fi
    download_from_url_to_a_filepath "${EXTRA_FONTS_URL}" "${ARTIFACT_DIRECTORY_FONTS}/fonts.tar.gz"
}

function download_marlin()  {
    IFS='.' read -r -a marlin_v_arr <<< "$MARLIN_VERSION"
    unset IFS

    marlin_major=${marlin_v_arr[0]}
    marlin_minor=${marlin_v_arr[1]}
    marlin_patch=${marlin_v_arr[2]}

    if [ ! -e "${ARTIFACT_DIRECTORY_MARLIN}" ]; then
        mkdir -p "${ARTIFACT_DIRECTORY_MARLIN}"
    fi

    marlin_url_1="https://github.com/bourgesl/marlin-renderer/releases/download/v${marlin_major}_${marlin_minor}_${marlin_patch}/marlin-${marlin_major}.${marlin_minor}.${marlin_patch}-Unsafe.jar"
    marlin_url_2="https://github.com/bourgesl/marlin-renderer/releases/download/v${marlin_major}_${marlin_minor}_${marlin_patch}/marlin-${marlin_major}.${marlin_minor}.${marlin_patch}-Unsafe-sun-java2d.jar"
    download_from_url_to_a_filepath "${marlin_url_1}" "${ARTIFACT_DIRECTORY_MARLIN}/marlin-${marlin_major}.${marlin_minor}.${marlin_patch}-Unsafe.jar"
    download_from_url_to_a_filepath "${marlin_url_2}" "${ARTIFACT_DIRECTORY_MARLIN}/marlin-${marlin_major}.${marlin_minor}.${marlin_patch}-Unsafe-sun-java2d.jar"
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
    tar xzvf "${TEMP_FILE_PATH}" --strip=1 -C "${ARTIFACT_DIRECTORY_DATADIR}"
}

function build_with_data_dir() {

	get_release_artifact_url_from_github "${GITHUB_REPO}" "${GITHUB_REPO_OWNER}" "${GEOSERVER_DATA_DIR_RELEASE}"

	${DOCKER_BUILD_COMMAND} --no-cache \
		--build-arg BASE_IMAGE_NAME=gs-base \
		--build-arg BASE_IMAGE_TAG=7.0-jre8 \
		--build-arg INCLUDE_DATA_DIR=true \
		--build-arg INCLUDE_GS_WAR=true \
		--build-arg INCLUDE_PLUGINS=${INCLUDE_PLUGINS} \
		--build-arg ADD_MARLIN_RENDERER=true \
		--build-arg ADD_EXTRA_FONTS=false \
		--build-arg GEOSERVER_APP_NAME=geoserver \
		-t geosolutionsit/geoserver:"${TAG}" \
		 .
}

function build_without_data_dir() {

	${DOCKER_BUILD_COMMAND} --no-cache \
		--build-arg BASE_IMAGE_NAME=gs-base \
		--build-arg BASE_IMAGE_TAG=7.0-jre8 \
		--build-arg INCLUDE_DATA_DIR=false \
		--build-arg INCLUDE_GS_WAR=true \
		--build-arg INCLUDE_PLUGINS=${INCLUDE_PLUGINS} \
		--build-arg ADD_MARLIN_RENDERER=true \
		--build-arg ADD_EXTRA_FONTS=false \
		--build-arg GEOSERVER_APP_NAME=geoserver \
		-t geosolutionsit/geoserver:"${TAG}"     \
		 .
}

function build() {
    help ${ALL_PARAMETERS}

    if [[ "${PULL}" == "pull" ]]; then
        DOCKER_BUILD_COMMAND="docker build --pull"
    else
        DOCKER_BUILD_COMMAND="docker build"
    fi;

    download_marlin

	case ${GEOSERVER_DATA_DIR_RELEASE} in
		"dev")
			build_without_data_dir ${TAG} ${PULL}
			;;
		*)
            clean_up_directory ${ARTIFACT_DIRECTORY_DATADIR}
			build_with_data_dir ${TAG} ${PULL}
			;;
    esac
}

build