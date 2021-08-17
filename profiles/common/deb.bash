#!/bin/bash -x

# fail on error
set -e
set -o pipefail

CCWS_DEB_ENABLE="yes"
export CCWS_DEB_ENABLE


source ${WORKSPACE_DIR}/profiles/${PROFILE}/setup.bash

CCWS_DEB_VERSION=${CCWS_BUILD_TIME}
if [ -f "${WORKSPACE_DIR}/build/version_hash/${PKG}" ]
then
    CCWS_DEB_VERSION="${CCWS_DEB_VERSION}_$(cat ${WORKSPACE_DIR}/build/version_hash/${PKG})"
fi
CCWS_DEB_VERSION=$(echo "${CCWS_DEB_VERSION}" | sed 's/_/-/g')

export CCWS_DEB_VERSION


if [ -z "${CCWS_SYSROOT}" ]
then
    # native build

    # we are still going to use proot in order to be able to install things to
    # 'system' paths
    # CMAKE_STAGING_PREFIX could probably be useful, but colcon installs things
    # too

    PATH=${CCWS_PROOT_BIN}:/bin:${PATH}
    export PATH

    CCWS_SYSROOT="/"
    export CCWS_SYSROOT
fi
