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

if command -v "rospack" > /dev/null
then
    # TODO is this still necessary?
    # sometimes packages cannot be located, this should fix such issues
    if type rospack > /dev/null;
    then
        rospack profile
    fi
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
    CCWS_ARTIFACTS_ROOT_DIR="${HOME}/ccws/artifacts/"
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

# enable line buffering -- useful when ROS output is piped to some log file (CI, system service)
# http://wiki.ros.org/rosconsole#Force_line_buffering_for_ROS_logger
ROSCONSOLE_STDOUT_LINE_BUFFERED=1
export ROSCONSOLE_STDOUT_LINE_BUFFERED


##########################################################################################
# tests
#

# Force ROS macros to log color even in colcon test
RCUTILS_COLORIZED_OUTPUT=1
export RCUTILS_COLORIZED_OUTPUT

# Force color on gtest
GTEST_COLOR=1
export GTEST_COLOR


##########################################################################################
# python
#

# https://answers.ros.org/question/394564/colcon-not-adding-python-module-built-with-cmake-to-pythonpath/
for PYTHONDIR in "${COLCON_CURRENT_PREFIX}/lib/python"*"/site-packages";
do
    if [ -d "${PYTHONDIR}" ] # matching is a bit sketchy
    then
        if [ -z "${PYTHONPATH}" ]
        then
            PYTHONPATH="${PYTHONDIR}"
        else
            case ${PYTHONPATH} in
                *${PYTHONDIR}*) ;;
                *) PYTHONPATH="${PYTHONPATH}:${PYTHONDIR}";;
            esac
        fi
    fi
done
export PYTHONPATH


# TODO prevents generation of *.pyc files, which are not removed when package
# is uninstalled, a more appropriate thing to do is to add prerm script to
# debian package
PYTHONDONTWRITEBYTECODE=1
export PYTHONDONTWRITEBYTECODE

##########################################################################################
