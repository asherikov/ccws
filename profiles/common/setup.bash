#!/bin/bash -x
# shellcheck disable=SC1090

##########################################################################################

CCWS_VENDOR_ID=ccws
export CCWS_VENDOR_ID

# assuming that this preload is sourced from the root of the workspace
CCWS_WORKSPACE_DIR=$(pwd)
export CCWS_WORKSPACE_DIR

CCWS_ARTIFACTS_DIR="${CCWS_WORKSPACE_DIR}/artifacts"
export CCWS_ARTIFACTS_DIR

CCWS_STATIC_PATH_EXCEPTIONS=""
export CCWS_STATIC_PATH_EXCEPTIONS

if [ -z "${CCWS_ROS_DISTRO}" ];
then
    # CCWS_SYSROOT is empty by default
    if [ -d "${CCWS_SYSROOT}/opt/ros/" ];
    then
        CCWS_ROS_DISTRO=$(ls "${CCWS_SYSROOT}/opt/ros/")
        export CCWS_ROS_DISTRO
    else
        echo "Could not determine CCWS_ROS_DISTRO"
    fi
fi

CCWS_PROFILE_DIR="${CCWS_WORKSPACE_DIR}/profiles/${CCWS_PROFILE}"
export CCWS_PROFILE_DIR

CCWS_PROFILE_BUILD_DIR="${CCWS_WORKSPACE_DIR}/build/${CCWS_PROFILE}"
export CCWS_PROFILE_BUILD_DIR


CCWS_PROOT_BIN="${CCWS_WORKSPACE_DIR}/profiles/common/proot_bin"
export CCWS_PROOT_BIN


##########################################################################################
# installation path
#

INSTALL_PATH_PREFIX="${CCWS_WORKSPACE_DIR}/install/"

# architecture is a part of target triple set by crosscompilation profiles
if [ -z "${CCWS_TRIPLE_ARCH}" ];
then
    CCWS_TRIPLE_ARCH=$(uname -m)
fi

case "$PKG" in
    *\ *)
        # contains spaces = multiple packages provided
        if [ -n "${CCWS_VENDOR_ID}" ]
        then
            INSTALL_PKG_PREFIX="${CCWS_VENDOR_ID}__"
        fi
        ;;
    *)
        INSTALL_PKG_PREFIX="${PKG}__"
        ;;
esac

CCWS_BUILD_COMMIT=$(git show -s --format=%h)
CCWS_BUILD_TIME=$(date '+%Y%m%d_%H%M')
CCWS_BUILD_USER=$(whoami)

CCWS_PROFILE_TARGET_INSTALL_DIR="/opt/${CCWS_VENDOR_ID}/${INSTALL_PKG_PREFIX}${CCWS_TRIPLE_ARCH}__${CCWS_PROFILE}__${CCWS_BUILD_USER}_${CCWS_BUILD_COMMIT}"
CCWS_PROFILE_WORKING_INSTALL_DIR="${CCWS_WORKSPACE_DIR}/install/${CCWS_PROFILE_TARGET_INSTALL_DIR}"
CCWS_WORKSPACE_SETUP="${CCWS_PROFILE_WORKING_INSTALL_DIR}/local_setup.sh"

export CCWS_PROFILE_TARGET_INSTALL_DIR CCWS_PROFILE_WORKING_INSTALL_DIR CCWS_WORKSPACE_SETUP CCWS_BUILD_COMMIT CCWS_BUILD_TIME CCWS_BUILD_USER


##########################################################################################
# doxygen
#
CCWS_DOXYGEN_OUTPUT_DIR="${CCWS_ARTIFACTS_DIR}/doxygen"
CCWS_DOXYGEN_CONFIG_DIR="${CCWS_WORKSPACE_DIR}/profiles/common/doc"
CCWS_DOXYGEN_WORKING_DIR="${CCWS_WORKSPACE_DIR}/build/doxygen"

export CCWS_DOXYGEN_OUTPUT_DIR CCWS_DOXYGEN_CONFIG_DIR CCWS_DOXYGEN_WORKING_DIR


##########################################################################################
# ccache
#
# keep ccache in the workspace, this is handy when workspace is mounted inside dockers
export CCACHE_DIR=${CCWS_WORKSPACE_DIR}/.ccache


##########################################################################################
# colcon
#

# not necessary?
CMAKE_TOOLCHAIN_FILE=${CCWS_PROFILE_DIR}/toolchain.cmake
export CMAKE_TOOLCHAIN_FILE

#COLCON_DEFAULTS_FILE="${CCWS_WORKSPACE_DIR}/${CCWS_PROFILE}/colcon.yaml"
#export COLCON_DEFAULTS_FILE

COLCON_HOME="${CCWS_WORKSPACE_DIR}/common/"
if [ -z "${CCWS_USE_BIN_PKG_LAYOUT}" ]
then
    COLCON_INSTALL_BASE=${CCWS_PROFILE_WORKING_INSTALL_DIR};
else
    COLCON_INSTALL_BASE=${CCWS_PROFILE_TARGET_INSTALL_DIR};
fi

# --log-level DEBUG
COLCON_BUILD_ARGS="--install-base ${COLCON_INSTALL_BASE} --base-paths src/ --cmake-args -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}"
COLCON_TEST_ARGS="--install-base ${COLCON_INSTALL_BASE} --test-result-base log/${CCWS_PROFILE}/testing"
COLCON_LIST_ARGS="--topological-order --names-only --base-paths src/"

export COLCON_HOME COLCON_BUILD_ARGS COLCON_TEST_ARGS COLCON_LIST_ARGS


##########################################################################################
# ROS
#

# try sourcing preload scripts
if [ -f "/opt/ros/${CCWS_ROS_DISTRO}/setup.bash" ];
then
    source "/opt/ros/${CCWS_ROS_DISTRO}/setup.bash"
fi
if [ -f "${CCWS_WORKSPACE_SETUP}" ];
then
    source "${CCWS_WORKSPACE_SETUP}"
fi


ROS_HOME="${CCWS_ARTIFACTS_DIR}"
export ROS_HOME

ROS_LOG_DIR="${CCWS_ARTIFACTS_DIR}/ros_log"
export ROS_LOG_DIR

# Disable Lisp & Javascript message and service generators
#   gencpp - C++ ROS message and service generators.
#   geneus - EusLisp ROS message and service generators.
#   genlisp - Common-Lisp ROS message and service generators.
#   genmsg - Standalone Python library for generating ROS message and service data structures for various languages.
#   gennodejs - Javascript ROS message and service generators.
#   genpy - Python ROS message and service generators.
ROS_LANG_DISABLE="genlisp;geneus;gennodejs"
export ROS_LANG_DISABLE

# Expressions don't expand in single quotes, use double quotes for that.
# shellcheck disable=SC2016
ROSCONSOLE_FORMAT='[${severity}] [${time}] [${node}]: ${message}'
export ROSCONSOLE_FORMAT

#ROSCONSOLE_CONFIG_FILE=
#export ROSCONSOLE_CONFIG_FILE


##########################################################################################
# other
#
MAKEFLAGS="-j${JOBS}"
export MAKEFLAGS
