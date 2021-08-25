#!/bin/bash -x

# fail on error
set -e
set -o pipefail

CCWS_DEB_ENABLE="yes"
export CCWS_DEB_ENABLE


source "${BUILD_PROFILES_DIR}/${PROFILE}/setup.bash"


CCWS_DEB_INFO_DIR="${CCWS_INSTALL_DIR_BUILD}/ccws/"
export CCWS_DEB_INFO_DIR


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
