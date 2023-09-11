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
# LLVM version
#
case "${OS_DISTRO_HOST}" in
    focal)
        CCWS_LLVM_VERSION=12;;
    jammy)
        CCWS_LLVM_VERSION=12;;
esac
export CCWS_LLVM_VERSION


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
# nix
#

if test -f "${CCWS_SOURCE_DIR}/flake.nix"
then
    CCWS_NIX="nix --extra-experimental-features nix-command --extra-experimental-features flakes"
    export CCWS_NIX

    source "${HOME}/.nix-profile/etc/profile.d/nix.sh"

    CCWS_BUILD_DIR_NIX="${CCWS_BUILD_DIR}/nix"

    mkdir -p "${CCWS_BUILD_DIR_NIX}"
    ${CCWS_NIX} develop "${CCWS_SOURCE_DIR}" --command env > "${CCWS_BUILD_DIR_NIX}/env"

    #PATH="$(grep '^PATH=' < "${CCWS_BUILD_DIR_NIX}/env" | sed 's/^PATH=//'):${PATH}"


    # nix compilers mess up CMAKE_LIBRARY_ARCHITECTURE
    if [ -z "${CC}" ]
    then
        CC=/usr/bin/gcc
        export CC
    fi
    if [ -z "${CXX}" ]
    then
        CXX=/usr/bin/g++
        export CXX
    fi


    NIX_CMAKE_PREFIX_PATH="$(grep '^CMAKE_PREFIX_PATH=' < "${CCWS_BUILD_DIR_NIX}/env" | sed 's/^CMAKE_PREFIX_PATH=//' || echo -n '')"
    NIX_CMAKE_LIBRARY_PATH="$(grep '^CMAKE_LIBRARY_PATH=' < "${CCWS_BUILD_DIR_NIX}/env" | sed 's/^CMAKE_LIBRARY_PATH=//' || echo -n '')"
    NIX_CMAKE_INCLUDE_PATH="$(grep '^CMAKE_INCLUDE_PATH=' < "${CCWS_BUILD_DIR_NIX}/env" | sed 's/^CMAKE_INCLUDE_PATH=//' || echo -n '')"

    if [ -n "${NIX_CMAKE_PREFIX_PATH}" ]
    then
        CMAKE_PREFIX_PATH="${NIX_CMAKE_PREFIX_PATH}:${CMAKE_PREFIX_PATH}"
        export CMAKE_PREFIX_PATH
    fi
    if [ -n "${NIX_CMAKE_LIBRARY_PATH}" ]
    then
        CMAKE_LIBRARY_PATH="${NIX_CMAKE_LIBRARY_PATH}:${CMAKE_LIBRARY_PATH}"
        export CMAKE_LIBRARY_PATH
        LD_LIBRARY_PATH="${NIX_CMAKE_LIBRARY_PATH}:${LD_LIBRARY_PATH}"
        export LD_LIBRARY_PATH
    fi
    if [ -n "${NIX_CMAKE_INCLUDE_PATH}" ]
    then
        CMAKE_INCLUDE_PATH="${NIX_CMAKE_INCLUDE_PATH}:${CMAKE_INCLUDE_PATH}"
        export CMAKE_INCLUDE_PATH
    fi
fi


##########################################################################################
# other
#
MAKEFLAGS="-j${JOBS}"
export MAKEFLAGS

umask u=rwx,g=rx,o=rx

# prevent apt from being interactive
DEBIAN_FRONTEND=noninteractive
export DEBIAN_FRONTEND

