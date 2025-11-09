#!/bin/bash -x

# fail on error
set -e
set -o pipefail

##########################################################################################
CCWS_PRIMARY_BUILD_PROFILE=${CCWS_PRIMARY_BUILD_PROFILE:-"$(basename "$(dirname "${BASH_SOURCE[0]}")")"}
source "$(dirname "${BASH_SOURCE[0]}")/../${1:-"common"}/setup.bash" "${@:2}" ""


##########################################################################################
# doxygen
#
CCWS_DOXYGEN_OUTPUT_DIR="${CCWS_ARTIFACTS_DIR}"
CCWS_DOXYGEN_CONFIG_DIR="${BUILD_PROFILES_DIR}/doxygen"
CCWS_DOXYGEN_WORKING_DIR="${CCWS_BUILD_DIR}"

export CCWS_DOXYGEN_OUTPUT_DIR CCWS_DOXYGEN_CONFIG_DIR CCWS_DOXYGEN_WORKING_DIR
