#!/bin/bash

set -e

BUILD_TYPE=${1}
TAG=${2}
PULL_ENABLED=${3}

function build_with_data_dir() {

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