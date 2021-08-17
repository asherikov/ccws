#!/bin/bash
COLCON_CURRENT_PREFIX=$(dirname ${BASH_SOURCE})
source ${COLCON_CURRENT_PREFIX}/local_setup.sh

ROSCONSOLE_FORMAT='[${severity}] [${time}] [${node}]: ${message}'
export ROSCONSOLE_FORMAT

ROS_HOSTNAME=localhost
export ROS_HOSTNAME

# TODO prevents generation of *.pyc files, which are not removed when package
# is uninstalled, a more appropriate thing to do is to add prerm script to
# debian package
PYTHONDONTWRITEBYTECODE=1
export PYTHONDONTWRITEBYTECODE
