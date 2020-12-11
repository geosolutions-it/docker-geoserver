#!/bin/bash
# You should modify parameters (8) to consider your own custom build
# TODO: work on custom_build for releases that are not SNAPSHOTS -> ./custom_build.sh gs-2.18.1 2.18.x 2.18.1 dummy dummy dummy dev no-pull
# instead doing it manually
docker build --build-arg=GEOSERVER_WEBAPP_SRC=./geoserver.war . -t gs_unavco
