#!/bin/bash -x

# fail on error
set -e
set -o pipefail

##########################################################################################

# if node launch script respects CCWS_NODE_CRASH_ACTION the node crash
# becomes critical, see pkg_template/catkin/launch/bringup.launch
CCWS_NODE_CRASH_ACTION="killall"
export CCWS_NODE_CRASH_ACTION

##########################################################################################
