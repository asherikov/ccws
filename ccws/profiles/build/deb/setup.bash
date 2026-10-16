#!/bin/bash -x

# fail on error
set -e
set -o pipefail



##########################################################################################
CCWS_PRIMARY_BUILD_PROFILE=${CCWS_PRIMARY_BUILD_PROFILE:-"$(basename "$(dirname "${BASH_SOURCE[0]}")")"}
CCWS_SECONDARY_BUILD_PROFILE=${1:-"${CCWS_SECONDARY_BUILD_PROFILE}"}
if [ -z "${CCWS_SECONDARY_BUILD_PROFILE}" ]
then
    echo "Build profile cannot be chosen automatically for 'deb' mixin, make sure that secondary profile is set."
    return 0
fi

##########################################################################################
# override parameters usually set in common/setup.bash
#

if [ -z "${INSTALL_PKG_PREFIX}" ]
then
    case "${PKG}" in
        *\ *)
            # contains spaces = multiple packages provided
            if [ -n "${VENDOR}" ]
            then
                INSTALL_PKG_PREFIX="${VENDOR}"
            fi
            ;;
        *)
            INSTALL_PKG_PREFIX="${PKG}"
            ;;
    esac
fi

CCWS_PKG_FULL_NAME=${INSTALL_PKG_PREFIX}__$(echo "${CCWS_BUILD_PROFILES_TAIL}" | sed -e 's/,/_/g')__$(echo "${VERSION}" | sed -e 's/[[:punct:]]/_/g' -e 's/[[:space:]]/_/g')

CCWS_INSTALL_DIR_HOST="/opt/${VENDOR}/${CCWS_PKG_FULL_NAME}"
# shellcheck disable=SC2153
CCWS_INSTALL_DIR_BUILD_ROOT="${CCWS_INSTALL_DIR}/${CCWS_PKG_FULL_NAME}"
CCWS_INSTALL_DIR_BUILD="${CCWS_INSTALL_DIR_BUILD_ROOT}/${CCWS_INSTALL_DIR_HOST}"

export CCWS_INSTALL_DIR_BUILD_ROOT CCWS_INSTALL_DIR_HOST


CMAKE_TOOLCHAIN_FILE=${BUILD_PROFILES_DIR}/${CCWS_SECONDARY_BUILD_PROFILE}/toolchain.cmake


##########################################################################################
source "$(dirname "${BASH_SOURCE[0]}")/../${CCWS_SECONDARY_BUILD_PROFILE}/setup.bash" "${@:2}" ""


##########################################################################################
CCWS_DEBIAN_DIR="${CCWS_INSTALL_DIR_BUILD_ROOT}/DEBIAN/"
CCWS_DEBIAN_POSTINST_DIR="${CCWS_INSTALL_DIR_BUILD_ROOT}/DEBIAN/postinst_dir"
CCWS_DEBIAN_PREINST_DIR="${CCWS_INSTALL_DIR_BUILD_ROOT}/DEBIAN/preinst_dir"
CCWS_DEBIAN_POSTRM_DIR="${CCWS_INSTALL_DIR_BUILD_ROOT}/DEBIAN/postrm_dir"
CCWS_DEBIAN_PRERM_DIR="${CCWS_INSTALL_DIR_BUILD_ROOT}/DEBIAN/prerm_dir"

# binary subpackage generation switch, see the 'deb parameters' section for
# the description of the subpackages
CCWS_DEB_SUBPACKAGES="${CCWS_DEB_SUBPACKAGES:-OFF}"

# build metadata ('ccws' directory) is shipped in the main package, or in
# the 'dev' subpackage when subpackages are generated
CCWS_DEB_INFO_DIR="${CCWS_INSTALL_DIR_BUILD}/ccws/"
if [ "${CCWS_DEB_SUBPACKAGES}" = "ON" ]
then
    CCWS_DEB_INFO_DIR="${CCWS_INSTALL_DIR}/${CCWS_PKG_FULL_NAME}-dev${CCWS_INSTALL_DIR_HOST}/ccws/"
fi
export CCWS_DEB_INFO_DIR CCWS_DEBIAN_DIR CCWS_DEBIAN_POSTINST_DIR CCWS_DEBIAN_PREINST_DIR CCWS_DEBIAN_POSTRM_DIR CCWS_DEBIAN_PRERM_DIR


##########################################################################################
# deb parameters
#

CCWS_DEB_DEP_TYPE="${CCWS_DEB_DEP_TYPE:-run}"

# dependency list with 'build' dependencies for the 'dev' subpackage, kept
# separate from ${DEPLIST_FILE} which holds the dependencies of the main
# package
DEPLIST_FILE_DEV_DEPS="${DEPLIST_FILE}_build"

# binary subpackage generation switch (ON / OFF), see above; the subpackages
# cannot be selected individually -- when ON all of them are generated at
# once:
#   dev -- development files: headers, static libraries, CMake package
#          configurations, pkg-config files
#   dbg -- debug symbols: extracted from binaries and libraries, which are
#          stripped in the main package; symbols are installed into
#          '/usr/lib/debug/' and are located by gdb automatically
#   doc -- documentation files: documentation ('doc', 'man') directories and
#          markdown files

# staging root and output file of 'dpkg-deb', overridden for subpackages
CCWS_DEB_ROOT="${CCWS_DEB_ROOT:-${CCWS_INSTALL_DIR_BUILD_ROOT}}"
CCWS_DEB_OUTPUT="${CCWS_DEB_OUTPUT:-${CCWS_ARTIFACTS_DIR}/${CCWS_PKG_FULL_NAME}.deb}"

CCWS_DEB_SUBPACKAGE_DESCRIPTION_dev="development files"
CCWS_DEB_SUBPACKAGE_DESCRIPTION_dbg="debug symbols"
CCWS_DEB_SUBPACKAGE_DESCRIPTION_doc="documentation files"
# documentation packages are architecture independent
CCWS_DEB_SUBPACKAGE_ARCH_dev="${CCWS_DEB_ARCH}"
CCWS_DEB_SUBPACKAGE_ARCH_dbg="${CCWS_DEB_ARCH}"
CCWS_DEB_SUBPACKAGE_ARCH_doc="all"

export CCWS_DEB_DEP_TYPE CCWS_DEB_SUBPACKAGES CCWS_DEB_ROOT CCWS_DEB_OUTPUT DEPLIST_FILE_DEV_DEPS
export CCWS_DEB_SUBPACKAGE_DESCRIPTION_dev CCWS_DEB_SUBPACKAGE_DESCRIPTION_dbg CCWS_DEB_SUBPACKAGE_DESCRIPTION_doc
export CCWS_DEB_SUBPACKAGE_ARCH_dev CCWS_DEB_SUBPACKAGE_ARCH_dbg CCWS_DEB_SUBPACKAGE_ARCH_doc


if [ -z "${CCWS_SYSROOT_MOUNTPOINT}" ]
then
    # native build

    # we are still going to use proot in order to be able to install things to
    # 'system' paths
    # CMAKE_STAGING_PREFIX could probably be useful, but colcon installs things
    # too

    PATH=${CCWS_PROOT_BIN}:/bin:${PATH}
    export PATH

    CCWS_SYSROOT_MOUNTPOINT="/"
    export CCWS_SYSROOT_MOUNTPOINT
fi

CCWS_SOURCE_SCRIPT="${CCWS_INSTALL_DIR_BUILD}/${VENDOR}_setup.bash"
export CCWS_SOURCE_SCRIPT


case "${OS_DISTRO_HOST}" in
    bionic|focal|jammy|noble)
        CCWS_DEB_INSTALL_LIB="/lib";;
    resolute)
        CCWS_DEB_INSTALL_LIB="/usr/lib";;
esac

CCWS_SYSTEMD_INSTALL_DIR="${CCWS_DEB_INSTALL_LIB}/systemd/"
CCWS_UDEV_RULE_INSTALL_DIR="${CCWS_DEB_INSTALL_LIB}/udev/rules.d"
CCWS_SYSTEMD_UNIT_INSTALL_DIR="${CCWS_SYSTEMD_INSTALL_DIR}/system"
CCWS_SYSTEMD_NETWORK_INSTALL_DIR="${CCWS_SYSTEMD_INSTALL_DIR}/network"
CCWS_EXTRA_INSTALL_DIRS="${CCWS_SYSTEMD_INSTALL_DIR} ${CCWS_SYSTEMD_UNIT_INSTALL_DIR} ${CCWS_SYSTEMD_NETWORK_INSTALL_DIR} ${CCWS_UDEV_RULE_INSTALL_DIR}"
export CCWS_SYSTEMD_INSTALL_DIR CCWS_SYSTEMD_UNIT_INSTALL_DIR CCWS_SYSTEMD_NETWORK_INSTALL_DIR CCWS_UDEV_RULE_INSTALL_DIR CCWS_EXTRA_INSTALL_DIRS
