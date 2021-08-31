#!/bin/bash -x


##########################################################################################
# source scripts
#

if [ -n "${CCWS_INSTALL_DIR_BUILD}" ]
then
    COLCON_CURRENT_PREFIX=${CCWS_INSTALL_DIR_BUILD}
else
    COLCON_CURRENT_PREFIX=$(dirname "${BASH_SOURCE[0]}")
fi
if [ -z "${COLCON_CURRENT_PREFIX}/local_setup.sh" ]
then
    source "${COLCON_CURRENT_PREFIX}/local_setup.sh"
fi

# TODO is this still necessary?
# sometimes packages cannot be located, this should fix such issues
rospack profile


##########################################################################################
# CCWS
#

# if node launch script respects CCWS_NODE_CRASH_ACTION the crashed nodes
# are restarted automatically, see pkg_template/catkin/launch/bringup.launch
# redundant
#CCWS_NODE_CRASH_ACTION="respawn"
#export CCWS_NODE_CRASH_ACTION

if [ -z "${CCWS_ARTIFACTS_DIR}" ]
then
    CCWS_ARTIFACTS_ROOT_DIR="/media/artifacts/$(hostname)/"
    export CCWS_ARTIFACTS_ROOT_DIR

    CCWS_ARTIFACTS_DIR="${CCWS_ARTIFACTS_ROOT_DIR}/$(date '+%Y_%m_%d')"
    export CCWS_ARTIFACTS_DIR
fi


##########################################################################################
# ROS
#

ROS_HOME="${CCWS_ARTIFACTS_DIR}"
ROS_LOG_DIR="${ROS_HOME}/ros_log"
export ROS_HOME ROS_LOG_DIR

ROSCONSOLE_FORMAT='[${severity}] [${time}] [${node}]: ${message}'
export ROSCONSOLE_FORMAT

#ROSCONSOLE_CONFIG_FILE=
#export ROSCONSOLE_CONFIG_FILE

ROS_HOSTNAME=localhost
export ROS_HOSTNAME


##########################################################################################
# python
#

# TODO prevents generation of *.pyc files, which are not removed when package
# is uninstalled, a more appropriate thing to do is to add prerm script to
# debian package
PYTHONDONTWRITEBYTECODE=1
export PYTHONDONTWRITEBYTECODE
