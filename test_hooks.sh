#!/usr/bin/bash -x
export MAINT_VERSION="2.18.4 2.18.3 2.18.2 2.18.1 2.18.0"
export MIDDLE_STABLE="19"
export NIGHTLY_MAINT_VERSION="2.18.x"
export NIGHTLY_MASTER_VERSION="main foobar"
export NIGHTLY_STABLE_VERSION="2.19.x"
export STABLE_VERSION="2.19.2"
export DOCKERFILE_PATH="./Dockerfile"
export DOCKER_REPO="somethingnotreal"
source hooks/build
#source hooks/test
