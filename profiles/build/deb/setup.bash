#!/bin/bash -x

# fail on error
set -e
set -o pipefail


##########################################################################################
BUILD_PROFILE=${BUILD_PROFILE:-"$(basename "$(dirname "${BASH_SOURCE[0]}")")"}
BASE_BUILD_PROFILE=${1:-"$BASE_BUILD_PROFILE"}
if [ -z "${BASE_BUILD_PROFILE}" ]
then
    echo "Build profile cannot be chosen automatically for 'deb' mixin, make sure BASE_BUILD_PROFILE is set."
    false
fi


##########################################################################################
# override parameters usually set in common/setup.bash
#

CCWS_BUILD_DIR="${WORKSPACE_DIR}/build/${BUILD_PROFILE}_${BASE_BUILD_PROFILE}"

case "${PKG}" in
    *\ *)
        # contains spaces = multiple packages provided
        if [ -n "${VENDOR}" ]
        then
            INSTALL_PKG_PREFIX="${VENDOR}__"
        fi
        ;;
    *)
        INSTALL_PKG_PREFIX="${PKG}__"
        ;;
esac

CCWS_PKG_FULL_NAME=${INSTALL_PKG_PREFIX}${BASE_BUILD_PROFILE}__$(echo "${VERSION}" | sed -e 's/[[:punct:]]/_/g' -e 's/[[:space:]]/_/g')

CCWS_INSTALL_DIR_HOST="/opt/${VENDOR}/${CCWS_PKG_FULL_NAME}"
CCWS_INSTALL_DIR_BUILD_ROOT="${WORKSPACE_DIR}/install/${CCWS_PKG_FULL_NAME}"
CCWS_INSTALL_DIR_BUILD="${CCWS_INSTALL_DIR_BUILD_ROOT}/${CCWS_INSTALL_DIR_HOST}"

export CCWS_INSTALL_DIR_BUILD_ROOT CCWS_INSTALL_DIR_HOST


CMAKE_TOOLCHAIN_FILE=${BUILD_PROFILES_DIR}/${BASE_BUILD_PROFILE}/toolchain.cmake


##########################################################################################
source "$(dirname "${BASH_SOURCE[0]}")/../${BASE_BUILD_PROFILE}/setup.bash" "${@:2}" ""

case "${CCWS_TRIPLE_ARCH}" in
    # fixes 'package architecture (aarch64) does not match system (arm64)', deb
    # architecture naming conventions are different
    aarch64) CCWS_DEB_ARCH=arm64;;
    x86_64) CCWS_DEB_ARCH=amd64;;
    arm)
        case "${CCWS_TRIPLE_ABI}" in
            gnueabihf) CCWS_DEB_ARCH=armhf;;
            *) CCWS_DEB_ARCH=${CCWS_TRIPLE_ARCH};;
        esac;;
    *) CCWS_DEB_ARCH=${CCWS_TRIPLE_ARCH};;
esac

export CCWS_DEB_ARCH


##########################################################################################
CCWS_DEBIAN_DIR="${CCWS_INSTALL_DIR_BUILD_ROOT}/DEBIAN/"
CCWS_DEBIAN_POSTINST_DIR="${CCWS_INSTALL_DIR_BUILD_ROOT}/DEBIAN/postinst_dir"
CCWS_DEBIAN_PREINST_DIR="${CCWS_INSTALL_DIR_BUILD_ROOT}/DEBIAN/preinst_dir"
CCWS_DEBIAN_POSTRM_DIR="${CCWS_INSTALL_DIR_BUILD_ROOT}/DEBIAN/postrm_dir"
CCWS_DEBIAN_PRERM_DIR="${CCWS_INSTALL_DIR_BUILD_ROOT}/DEBIAN/prerm_dir"
CCWS_DEB_INFO_DIR="${CCWS_INSTALL_DIR_BUILD}/ccws/"
export CCWS_DEB_INFO_DIR CCWS_DEBIAN_DIR CCWS_DEBIAN_POSTINST_DIR CCWS_DEBIAN_PREINST_DIR CCWS_DEBIAN_POSTRM_DIR CCWS_DEBIAN_PRERM_DIR


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

CCWS_SOURCE_SCRIPT="${CCWS_INSTALL_DIR_BUILD}/${VENDOR}_setup.bash"
export CCWS_SOURCE_SCRIPT


CCWS_SYSTEMD_INSTALL_DIR="/lib/systemd/"
CCWS_SYSTEMD_UNIT_INSTALL_DIR="${CCWS_SYSTEMD_INSTALL_DIR}/system"
CCWS_SYSTEMD_NETWORK_INSTALL_DIR="${CCWS_SYSTEMD_INSTALL_DIR}/network"
CCWS_UDEV_RULE_INSTALL_DIR="/lib/udev/rules.d"
CCWS_EXTRA_INSTALL_DIRS="${CCWS_SYSTEMD_INSTALL_DIR} ${CCWS_SYSTEMD_UNIT_INSTALL_DIR} ${CCWS_SYSTEMD_NETWORK_INSTALL_DIR} ${CCWS_UDEV_RULE_INSTALL_DIR}"
export CCWS_SYSTEMD_INSTALL_DIR CCWS_SYSTEMD_UNIT_INSTALL_DIR CCWS_SYSTEMD_NETWORK_INSTALL_DIR CCWS_UDEV_RULE_INSTALL_DIR CCWS_EXTRA_INSTALL_DIRS
