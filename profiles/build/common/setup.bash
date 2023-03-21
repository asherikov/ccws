#!/bin/bash -x
##########################################################################################

# if not set assume that this preload is sourced from the root of the workspace
WORKSPACE_DIR=${WORKSPACE_DIR:-"$(pwd)"}
BUILD_PROFILES_DIR=${BUILD_PROFILES_DIR:-"${WORKSPACE_DIR}/profiles/build"}
export WORKSPACE_DIR BUILD_PROFILES_DIR


if [ -z "${BUILD_PROFILE}" ]
then
    echo "Profile is not defined"
    test -n "${BUILD_PROFILE}"
else
    echo "Selected profile: '${BUILD_PROFILE}'"
    export BUILD_PROFILE
fi

if [ -z "${CCWS_ARTIFACTS_DIR}" ]
then
    if [ -z "${ARTIFACTS_DIR}" ]
    then
        CCWS_ARTIFACTS_DIR="${WORKSPACE_DIR}/artifacts/${BUILD_PROFILE}"
    else
        CCWS_ARTIFACTS_DIR="${ARTIFACTS_DIR}/${BUILD_PROFILE}"
    fi
fi
CCWS_BUILD_PROFILE_DIR="${BUILD_PROFILES_DIR}/${BUILD_PROFILE}"
CCWS_BUILD_DIR=${CCWS_BUILD_DIR:-"${WORKSPACE_DIR}/build/${BUILD_PROFILE}"}
CCWS_LOG_DIR=${CCWS_LOG_DIR:-"${WORKSPACE_DIR}/build/log/${BUILD_PROFILE}"}
CCWS_SOURCE_DIR="${WORKSPACE_DIR}/src"
export CCWS_ARTIFACTS_DIR CCWS_BUILD_PROFILE_DIR CCWS_BUILD_DIR CCWS_SOURCE_DIR CCWS_LOG_DIR

CCWS_PROOT_BIN="${WORKSPACE_DIR}/scripts/proot"
export CCWS_PROOT_BIN


##########################################################################################
# Host OS & arch
#
if [ -z "${CCWS_SYSROOT}" ]
then
    OS_DISTRO_HOST=${OS_DISTRO_BUILD}
    export OS_DISTRO_HOST
fi

if [ -z "${CCWS_TRIPLE_ARCH}" ];
then
    CCWS_TRIPLE_ARCH=$(uname -m)
fi
export CCWS_TRIPLE_ARCH


CCWS_TRIPLE=${CCWS_TRIPLE_ARCH}-${CCWS_TRIPLE_SYS}-${CCWS_TRIPLE_ABI}
export CCWS_TRIPLE CCWS_TRIPLE_ARCH CCWS_TRIPLE_SYS CCWS_TRIPLE_ABI


##########################################################################################
# cross compilation
#

if [ -n "${CCWS_SYSROOT}" ]
then
    CCWS_CHROOT="chroot ${CCWS_SYSROOT}"
    export CCWS_SYSROOT CCWS_CHROOT

    # host root in emulation
    CCWS_BUILD_ROOTFS=/host-rootfs/
    export CCWS_BUILD_ROOTFS

    PATH=${CCWS_PROOT_BIN}:/bin:${PATH}
    export PATH

    # system package search parameters TODO redundant?
    # needed for non-proot crosscompilation
    #PKG_CONFIG_SYSROOT_DIR=${CCWS_SYSROOT}
    #PKG_CONFIG_PATH="${PKG_CONFIG_PATH}:${CCWS_SYSROOT}/usr/lib/pkgconfig:${CCWS_SYSROOT}/usr/lib/${CCWS_TRIPLE}/pkgconfig:${CCWS_SYSROOT}/usr/share/pkgconfig"
    #PKG_CONFIG_SYSROOT_DIR=/
    PKG_CONFIG_PATH="${PKG_CONFIG_PATH}:/usr/lib/pkgconfig:/usr/lib/${CCWS_TRIPLE}/pkgconfig:/usr/share/pkgconfig"
    export PKG_CONFIG_PATH

    # skip tests
    #COLCON_BUILD_ARGS="${COLCON_BUILD_ARGS} --catkin-skip-building-tests"
    #export COLCON_BUILD_ARGS
fi


##########################################################################################
# ROS version
#
if [ -z "${ROS_DISTRO}" ];
then
    # check installed ROS
    # CCWS_SYSROOT is empty in native builds and nonempty builds, so we are checking the host
    if [ -d "${CCWS_SYSROOT}/opt/ros/" ];
    then
        ROS_DISTRO=$(find "${CCWS_SYSROOT}/opt/ros/" -mindepth 1 -maxdepth 1 -type d | sort | tail -n 1 | xargs basename | sed 's=/==g')
    fi

    # pick default based on the OS version
    # ROS1 is preferred, override manually if necessary
    if [ -z "${ROS_DISTRO}" ];
    then
        case "${OS_DISTRO_HOST}" in
            bionic)
                ROS_DISTRO=melodic;;
            focal)
                ROS_DISTRO=noetic;;
            jammy)
                ROS_DISTRO=humble;;
        esac
    fi
fi
if [ -z "${ROS_DISTRO}" ]
then
    echo "Could not determine ROS_DISTRO" >&2
else
    echo "Selected ROS distro: '${ROS_DISTRO}'"
    export ROS_DISTRO
fi

# has to be set for colcon to determine dependencies properly
case "${ROS_DISTRO}" in
    melodic)
        ROS_PYTHON_VERSION=2;;
    *)
        ROS_PYTHON_VERSION=3;;
esac
export ROS_PYTHON_VERSION


##########################################################################################
# installation path
#

CCWS_BUILD_TIME=$(date '+%Y%m%d_%H%M')
CCWS_BUILD_USER=$(whoami)
export CCWS_BUILD_TIME CCWS_BUILD_USER


if [ -z "${CCWS_PKG_FULL_NAME}" ] # can be set elsewhere
then
    CCWS_PKG_FULL_NAME=${PKG}
    # CCWS_INSTALL_DIR_BUILD = CCWS_INSTALL_DIR_HOST
    CCWS_INSTALL_DIR_BUILD="${WORKSPACE_DIR}/install/${BUILD_PROFILE}"
    CCWS_INSTALL_DIR_HOST="${CCWS_INSTALL_DIR_BUILD}"
fi

export CCWS_PKG_FULL_NAME CCWS_INSTALL_DIR_HOST CCWS_INSTALL_DIR_BUILD


##########################################################################################
# cmake
#
# since 3.21: https://cmake.org/cmake/help/latest/envvar/CMAKE_TOOLCHAIN_FILE.html
CCWS_CXX_STANDARD=17
export CCWS_CXX_STANDARD

CMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE:-"${CCWS_BUILD_PROFILE_DIR}/toolchain.cmake"}
export CMAKE_TOOLCHAIN_FILE

# since 3.12: https://cmake.org/cmake/help/latest/envvar/CMAKE_BUILD_PARALLEL_LEVEL.html
if [ -n "${JOBS}" ]
then
    CMAKE_BUILD_PARALLEL_LEVEL=${JOBS}
    export CMAKE_BUILD_PARALLEL_LEVEL
fi


##########################################################################################
# cache
#
CCWS_CACHE=${CCWS_CACHE:-"${WORKSPACE_DIR}/cache"}
export CCWS_CACHE


##########################################################################################
# ccache
#
# keep ccache in the workspace, this is handy when workspace is mounted inside dockers
CCACHE_DIR=${CCACHE_DIR:-"${CCWS_CACHE}/ccache"}
# should help with absolute include paths
CCACHE_BASEDIR="${WORKSPACE_DIR}"
# TODO can mess up debug info paths, needs testing
CCACHE_NOHASHDIR="YES"
CCACHE_MAXSIZE=${CCACHE_MAXSIZE:-"8G"}
#CCACHE_LOGFILE=${CCWS_ARTIFACTS_DIR}/ccache.log
#CCACHE_LOGFILE=${CCWS_BUILD_DIR}/ccache.log
#export CCACHE_LOGFILE
export CCACHE_DIR CCACHE_BASEDIR CCACHE_MAXSIZE CCACHE_NOHASHDIR


##########################################################################################
# colcon
#

# does not seem to work
#COLCON_DEFAULTS_FILE="${BUILD_PROFILES_DIR}/common/colcon/defaults.yaml"
#export COLCON_DEFAULTS_FILE

COLCON_HOME="${BUILD_PROFILES_DIR}/common/colcon"
export COLCON_HOME


##########################################################################################
# ROS
#

# try sourcing preload scripts

# host ROS
SOURCE_SCRIPT="/opt/ros/${ROS_DISTRO}/setup.bash"
if [ -f "${SOURCE_SCRIPT}" ];
then
    source "${SOURCE_SCRIPT}"

    CCWS_EXTRA_SOURCE_SCRIPTS="${SOURCE_SCRIPT}"
    export CCWS_EXTRA_SOURCE_SCRIPTS
fi


# built packages
SOURCE_SCRIPT="${CCWS_INSTALL_DIR_BUILD}/local_setup.bash"
if [ -f "${SOURCE_SCRIPT}" ];
then
    COLCON_CURRENT_PREFIX="${CCWS_INSTALL_DIR_BUILD}"
    source "${SOURCE_SCRIPT}"
fi


# Disable Lisp & Javascript message and service generators
#   gencpp - C++ ROS message and service generators.
#   geneus - EusLisp ROS message and service generators.
#   genlisp - Common-Lisp ROS message and service generators.
#   genmsg - Standalone Python library for generating ROS message and service data structures for various languages.
#   gennodejs - Javascript ROS message and service generators.
#   genpy - Python ROS message and service generators.
ROS_LANG_DISABLE="genlisp;geneus;gennodejs"
export ROS_LANG_DISABLE


##########################################################################################
# other
#
MAKEFLAGS="-j${JOBS}"
export MAKEFLAGS

umask u=rwx,g=rx,o=rx

# prevent apt from being interactive
DEBIAN_FRONTEND=noninteractive
export DEBIAN_FRONTEND

