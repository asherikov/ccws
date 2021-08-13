#!/bin/bash
COLCON_CURRENT_PREFIX=$(dirname ${BASH_SOURCE})
source ${COLCON_CURRENT_PREFIX}/local_setup.sh

ROSCONSOLE_FORMAT='[${severity}] [${time}] [${node}]: ${message}'
export ROSCONSOLE_FORMAT

ROS_HOSTNAME=localhost
export ROS_HOSTNAME

# may be useful
#PYTHONDONTWRITEBYTECODE=1
#export PYTHONDONTWRITEBYTECODE
