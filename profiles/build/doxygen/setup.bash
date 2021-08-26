#!/bin/bash -x

# fail on error
set -e
set -o pipefail

##########################################################################################

BUILD_PROFILE="$(basename "$(dirname "${BASH_SOURCE[0]}")")"
source "$(dirname "${BASH_SOURCE[0]}")/../common/setup.bash"


##########################################################################################
# doxygen
#
CCWS_DOXYGEN_OUTPUT_DIR="${CCWS_ARTIFACTS_DIR}/doxygen"
CCWS_DOXYGEN_CONFIG_DIR="${BUILD_PROFILES_DIR}/doxygen"
CCWS_DOXYGEN_WORKING_DIR="${WORKSPACE_DIR}/build/doxygen"

export CCWS_DOXYGEN_OUTPUT_DIR CCWS_DOXYGEN_CONFIG_DIR CCWS_DOXYGEN_WORKING_DIR
