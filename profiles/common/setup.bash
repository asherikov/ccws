#!/bin/bash -x
##########################################################################################

# assuming that this preload is sourced from the root of the workspace
CCWS_WORKSPACE_DIR=$(pwd)
export CCWS_WORKSPACE_DIR

source "${CCWS_WORKSPACE_DIR}/profiles/common/config.bash"


CCWS_ARTIFACTS_DIR="${CCWS_WORKSPACE_DIR}/artifacts"
export CCWS_ARTIFACTS_DIR

if [ -z "${CCWS_ROS_DISTRO}" ];
then
    if [ -n "${ROS_DISTRO}" ];
    then
        CCWS_ROS_DISTRO=${ROS_DISTRO}
        export CCWS_ROS_DISTRO
    else
        # CCWS_SYSROOT is empty by default
        if [ -d "${CCWS_SYSROOT}/opt/ros/" ];
        then
            CCWS_ROS_DISTRO=$(find "${CCWS_SYSROOT}/opt/ros/" -mindepth 1 -maxdepth 1 -print0 -type d | xargs -0 basename | sort | tail -n 1 | sed 's=/==g')
            export CCWS_ROS_DISTRO
        else
            echo "Could not determine CCWS_ROS_DISTRO" >&2
        fi
    fi
fi

CCWS_PROFILE_DIR="${CCWS_WORKSPACE_DIR}/profiles/${CCWS_PROFILE}"
export CCWS_PROFILE_DIR

CCWS_BUILD_DIR="${CCWS_WORKSPACE_DIR}/build/${CCWS_PROFILE}"
export CCWS_BUILD_DIR


CCWS_PROOT_BIN="${CCWS_WORKSPACE_DIR}/scripts/proot"
export CCWS_PROOT_BIN


##########################################################################################
# installation path
#

CCWS_BUILD_TIME=$(date '+%Y%m%d_%H%M')
CCWS_BUILD_USER=$(whoami)
export CCWS_BUILD_TIME CCWS_BUILD_USER


if [ -z "${CCWS_DEB_ENABLE}" ]
then
    CCWS_PKG_FULL_NAME=${PKG}
    # CCWS_INSTALL_DIR_HOST = CCWS_INSTALL_DIR_TARGET
    CCWS_INSTALL_DIR_HOST="${CCWS_WORKSPACE_DIR}/install/${CCWS_PROFILE}"
    CCWS_INSTALL_DIR_TARGET="${CCWS_INSTALL_DIR_HOST}"
else
    if [ -z "${CCWS_TRIPLE_ARCH}" ];
    then
        CCWS_TRIPLE_ARCH=$(uname -m)
    fi

    # package name
    case "${PKG}" in
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

    CCWS_PKG_FULL_NAME=${INSTALL_PKG_PREFIX}${CCWS_TRIPLE_ARCH}__${CCWS_PROFILE}__$(echo "${VERSION}" | sed -e 's/[[:punct:]]/_/g' -e 's/[[:space:]]/_/g')

    CCWS_INSTALL_DIR_TARGET="/opt/${CCWS_VENDOR_ID}/${CCWS_PKG_FULL_NAME}"
    CCWS_INSTALL_DIR_HOST_ROOT="${CCWS_WORKSPACE_DIR}/install/${CCWS_PKG_FULL_NAME}"
    CCWS_INSTALL_DIR_HOST="${CCWS_INSTALL_DIR_HOST_ROOT}/${CCWS_INSTALL_DIR_TARGET}"

    export CCWS_INSTALL_DIR_HOST_ROOT
fi
CCWS_WORKSPACE_SETUP="${CCWS_INSTALL_DIR_HOST}/setup.bash"

export CCWS_PKG_FULL_NAME CCWS_INSTALL_DIR_TARGET CCWS_INSTALL_DIR_HOST CCWS_WORKSPACE_SETUP


##########################################################################################
# ccache
#
# keep ccache in the workspace, this is handy when workspace is mounted inside dockers
CCACHE_DIR=${CCWS_WORKSPACE_DIR}/.ccache
CCACHE_BASEDIR="/opt/${CCWS_VENDOR_ID}"
export CCACHE_DIR CCACHE_BASEDIR


##########################################################################################
# colcon
#

# not necessary?
CMAKE_TOOLCHAIN_FILE=${CCWS_PROFILE_DIR}/toolchain.cmake
export CMAKE_TOOLCHAIN_FILE

#COLCON_DEFAULTS_FILE="${CCWS_WORKSPACE_DIR}/${CCWS_PROFILE}/colcon.yaml"
#export COLCON_DEFAULTS_FILE

COLCON_HOME="${CCWS_WORKSPACE_DIR}/common/"

# --log-level DEBUG
COLCON_BUILD_ARGS="--install-base ${CCWS_INSTALL_DIR_HOST} --base-paths src/ --cmake-args -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}"
COLCON_TEST_ARGS="--install-base ${CCWS_INSTALL_DIR_HOST} --test-result-base log/${CCWS_PROFILE}/testing"
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


ROS_HOME="${CCWS_ARTIFACTS_DIR}/${CCWS_PROFILE}"
ROS_LOG_DIR="${ROS_HOME}/ros_log"
export ROS_HOME ROS_LOG_DIR

# Disable Lisp & Javascript message and service generators
#   gencpp - C++ ROS message and service generators.
#   geneus - EusLisp ROS message and service generators.
#   genlisp - Common-Lisp ROS message and service generators.
#   genmsg - Standalone Python library for generating ROS message and service data structures for various languages.
#   gennodejs - Javascript ROS message and service generators.
#   genpy - Python ROS message and service generators.
ROS_LANG_DISABLE="genlisp;geneus;gennodejs"
export ROS_LANG_DISABLE

ROSCONSOLE_FORMAT='[${severity}] [${time}] [${node}]: ${message}'
export ROSCONSOLE_FORMAT

#ROSCONSOLE_CONFIG_FILE=
#export ROSCONSOLE_CONFIG_FILE


##########################################################################################
# other
#
MAKEFLAGS="-j${JOBS}"
export MAKEFLAGS

umask u=rwx,g=rx,o=rx
