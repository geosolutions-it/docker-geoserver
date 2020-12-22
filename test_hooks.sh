#!/usr/bin/bash -x
export MAINT_VERSION="2.17.3 2.17.2 2.17.1"
export MIDDLE_STABLE="18"
export NIGHTLY_MAINT_VERSION="2.17.x"
export NIGHTLY_MASTER_VERSION="master antani"
export NIGHTLY_STABLE_VERSION="2.18.x"
export STABLE_VERSION="2.18.1 2.18.0"
export DOCKERFILE_PATH="./Dockerfile"
export DOCKER_REPO="somethingnotreal"
source hooks/build
#source hooks/test
