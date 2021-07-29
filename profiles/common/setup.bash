#!/bin/bash -x
# shellcheck disable=SC1090

##########################################################################################

# assuming that this preload is sourced from the root of the workspace
CCWS_WORKSPACE_DIR=$(pwd)
CCWS_WORKSPACE_SETUP="${CCWS_WORKSPACE_DIR}/install/${CCWS_PROFILE}/setup.sh"
export CCWS_WORKSPACE_DIR
export CCWS_WORKSPACE_SETUP

CCWS_ARTIFACTS_DIR="${CCWS_WORKSPACE_DIR}/artifacts"
export CCWS_ARTIFACTS_DIR

CCWS_STATIC_PATH_EXCEPTIONS=""
export CCWS_STATIC_PATH_EXCEPTIONS

if [ ! -n "${CCWS_ROS_DISTRO}" ];
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

CCWS_ROS_ROOT="${CCWS_SYSROOT}/opt/ros/${CCWS_ROS_DISTRO}"
export CCWS_ROS_ROOT

CCWS_PROFILE_DIR="${CCWS_WORKSPACE_DIR}/profiles/${CCWS_PROFILE}"
export CCWS_PROFILE_DIR

CCWS_PROFILE_BUILD_DIR="${CCWS_WORKSPACE_DIR}/build/${CCWS_PROFILE}"
export CCWS_PROFILE_BUILD_DIR


##########################################################################################
# doxygen
#
CCWS_DOXYGEN_OUTPUT_DIR="${CCWS_ARTIFACTS_DIR}/doxygen"
export CCWS_DOXYGEN_OUTPUT_DIR

CCWS_DOXYGEN_CONFIG_DIR="${CCWS_WORKSPACE_DIR}/profiles/common/doc"
export CCWS_DOXYGEN_CONFIG_DIR

CCWS_DOXYGEN_WORKING_DIR="${CCWS_WORKSPACE_DIR}/build/doxygen"
export CCWS_DOXYGEN_WORKING_DIR


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
export COLCON_HOME

COLCON_BUILD_ARGS="--base-paths src/ --cmake-args -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}"
export COLCON_BUILD_ARGS

COLCON_TEST_ARGS="--test-result-base log/${CCWS_PROFILE}/testing"
export COLCON_TEST_ARGS

COLCON_LIST_ARGS="--topological-order --names-only --base-paths src/"
export COLCON_LIST_ARGS


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
