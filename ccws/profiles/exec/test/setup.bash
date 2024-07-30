#!/bin/bash -x

##########################################################################################

# if node launch script respects CCWS_NODE_CRASH_ACTION the node crash
# becomes critical, see ccws/pkg_template/catkin/launch/bringup.launch
CCWS_NODE_CRASH_ACTION="killall"
export CCWS_NODE_CRASH_ACTION

##########################################################################################
