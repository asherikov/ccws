#!/bin/bash -x


##########################################################################################
# source scripts
#

CCWS_SETUP="${BASH_SOURCE[0]}"
export CCWS_SETUP

if [ -n "${CCWS_INSTALL_DIR_BUILD}" ]
then
    COLCON_CURRENT_PREFIX=${CCWS_INSTALL_DIR_BUILD}
else
    COLCON_CURRENT_PREFIX=$(dirname "${CCWS_SETUP}")
fi
if [ -f "${COLCON_CURRENT_PREFIX}/local_setup.sh" ]
then
    for SETUP_SCRIPT in ${CCWS_EXTRA_SOURCE_SCRIPTS};
    do
        if [ -f "${SETUP_SCRIPT}" ]
        then
            source "${SETUP_SCRIPT}";
            if [ -t 0 ];
            then
                # ignore errors to prevent session termination if interactive
                set +e
            fi
        fi
    done

    source "${COLCON_CURRENT_PREFIX}/local_setup.sh"
fi

# TODO is this still necessary?
# sometimes packages cannot be located, this should fix such issues
if type rospack > /dev/null;
then
    rospack profile
fi


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
