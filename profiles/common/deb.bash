#!/bin/bash -x

# fail on error
set -e
set -o pipefail

CCWS_DEB_ENABLE="yes"
export CCWS_DEB_ENABLE


source ${WORKSPACE_DIR}/profiles/${PROFILE}/setup.bash


# binary package architecture
case "${CCWS_TRIPLE_ARCH}" in
    # fixes 'package architecture (aarch64) does not match system (arm64)', deb
    # architecture naming conventions are different
    aarch64) CCWS_DEB_ARCH=arm64;;
    x86_64) CCWS_DEB_ARCH=amd64;;

    *) CCWS_DEB_ARCH=${CCWS_TRIPLE_ARCH};;
esac


DEB_VERSION=${CCWS_BUILD_TIME}
if [ -f "${WORKSPACE_DIR}/build/version_hash/${PKG}" ]
then
    DEB_VERSION="${DEB_VERSION}_$(cat ${WORKSPACE_DIR}/build/version_hash/${PKG})"
fi


CCWS_DEB_CONTROL="\
Package: $(echo "${CCWS_PKG_FULL_NAME}" | sed 's/_/-/g')
Version: $(echo "${DEB_VERSION}" | sed 's/_/-/g')
Architecture: ${CCWS_DEB_ARCH}
Maintainer: ${AUTHOR} <${EMAIL}>
Description: ${CCWS_VENDOR_ID} ${PKG}"
export CCWS_DEB_CONTROL


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
