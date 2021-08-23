#!/bin/bash -x

# fail on error
set -e
set -o pipefail

##########################################################################################

PROFILE="$(basename "$(dirname "${BASH_SOURCE[0]}")")"
source "./profiles/common/setup.bash"


##########################################################################################
# doxygen
#
CCWS_DOXYGEN_OUTPUT_DIR="${CCWS_ARTIFACTS_DIR}/doxygen"
CCWS_DOXYGEN_CONFIG_DIR="${CCWS_WORKSPACE_DIR}/profiles/doxygen"
CCWS_DOXYGEN_WORKING_DIR="${CCWS_WORKSPACE_DIR}/build/doxygen"

export CCWS_DOXYGEN_OUTPUT_DIR CCWS_DOXYGEN_CONFIG_DIR CCWS_DOXYGEN_WORKING_DIR
