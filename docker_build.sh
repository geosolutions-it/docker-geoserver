#!/bin/bash

set -e

BUILD_TYPE=${1}
TAG=${2}
PULL_ENABLED=${3}

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

function build_with_data_dir() {

	get_release_artifact_url_from_github "${GITHUB_REPO}" "${GITHUB_REPO_OWNER}" "${GEOSERVER_DATA_DIR_RELEASE}"

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
		--build-arg INCLUDE_DATA_DIR=true \
		--build-arg INCLUDE_GS_WAR=true \
		--build-arg INCLUDE_PLUGINS=true \
		--build-arg ADD_MARLIN_RENDERER=true \
		--build-arg ADD_EXTRA_FONTS=false \
		--build-arg GEOSERVER_APP_NAME=geoserver \
		-t geosolutionsit/geoserver:"${TAG}" \
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
		--build-arg ADD_MARLIN_RENDERER=true \
		--build-arg ADD_EXTRA_FONTS=false \
		--build-arg GEOSERVER_APP_NAME=geoserver \
		-t geosolutionsit/geoserver:"${TAG}"     \
		 .
}

function build() {

	case ${BUILD_TYPE} in
		"build_with_data_dir")
			build_with_data_dir ${TAG} ${PULL_ENABLED}
			;;
		"build_without_data_dir")
			build_without_data_dir ${TAG} ${PULL_ENABLED}
			;;
		*)
    esac
}

build