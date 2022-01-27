#!/bin/bash -x

##########################################################################################
# core files
#

CCWS_CORE_DIR="${CCWS_ARTIFACTS_DIR}/core/"
CCWS_CORE_PATTERN="${CCWS_CORE_DIR}/%e.%p.%t.core"
export CCWS_CORE_DIR CCWS_CORE_PATTERN

sudo /sbin/sysctl -w "kernel.core_pattern=${CCWS_CORE_PATTERN}"

ulimit -c unlimited


##########################################################################################
