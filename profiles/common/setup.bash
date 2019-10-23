#!/bin/bash -x
# shellcheck disable=SC1090

##########################################################################################

# assuming that this preload is sourced from the root of the workspace
CCW_WORKSPACE_DIR=$(pwd)
CCW_WORKSPACE_SETUP="${CCW_WORKSPACE_DIR}/install/${CCW_PROFILE}/setup.sh"
export CCW_WORKSPACE_SETUP

CCW_ARTIFACTS_DIR="${CCW_WORKSPACE_DIR}/artifacts"
export CCW_ARTIFACTS_DIR

CCW_STATIC_PATH_EXCEPTIONS=""
export CCW_STATIC_PATH_EXCEPTIONS

if [ ! -n "${CCW_ROS_DISTRO}" ];
then
    CCW_ROS_DISTRO=$(ls /opt/ros/)
    export CCW_ROS_DISTRO
fi


##########################################################################################
# doxygen
#
CCW_DOXYGEN_OUTPUT_DIR="${CCW_ARTIFACTS_DIR}/doxygen"
export CCW_DOXYGEN_OUTPUT_DIR

CCW_DOXYGEN_CONFIG_DIR="${CCW_WORKSPACE_DIR}/profiles/common/doc"
export CCW_DOXYGEN_CONFIG_DIR

CCW_DOXYGEN_WORKING_DIR="${CCW_WORKSPACE_DIR}/build/doxygen"
export CCW_DOXYGEN_WORKING_DIR


##########################################################################################
# colcon
#
#COLCON_DEFAULTS_FILE="${CCW_WORKSPACE_DIR}/${CCW_PROFILE}/colcon.yaml"
#export COLCON_DEFAULTS_FILE

COLCON_HOME="${CCW_WORKSPACE_DIR}/common/"
export COLCON_HOME

COLCON_BUILD_ARGS="--cmake-args -DCMAKE_TOOLCHAIN_FILE=${CCW_WORKSPACE_DIR}/profiles/${CCW_PROFILE}/toolchain.cmake"
export COLCON_BUILD_ARGS

COLCON_TEST_ARGS="--test-result-base log/${CCW_PROFILE}/testing"
export COLCON_TEST_ARGS

COLCON_LIST_ARGS="--topological-order --names-only --base-paths src/"
export COLCON_LIST_ARGS


##########################################################################################
# ROS
#
source "/opt/ros/${CCW_ROS_DISTRO}/setup.bash"
if [ -f "${CCW_WORKSPACE_SETUP}" ];
then
    source "${CCW_WORKSPACE_SETUP}"
fi

ROS_HOME="${CCW_ARTIFACTS_DIR}"
export ROS_HOME

ROS_LOG_DIR="${CCW_ARTIFACTS_DIR}/ros_log"
export ROS_LOG_DIR

# Disable Lisp & Javascript message and service generators
ROS_LANG_DISABLE="genlisp;geneus;gennodejs"
export ROS_LANG_DISABLE

# Expressions don't expand in single quotes, use double quotes for that.
# shellcheck disable=SC2016
ROSCONSOLE_FORMAT='[${severity}] [${time}] [${node}]: ${message}'
export ROSCONSOLE_FORMAT

#ROSCONSOLE_CONFIG_FILE=
#export ROSCONSOLE_CONFIG_FILE

MAKEFLAGS="-j${JOBS}"
export MAKEFLAGS
