#!/bin/bash -x

# fail on error
set -e
set -o pipefail

##########################################################################################

CCWS_PROFILE="reldebug"
export CCWS_PROFILE

source "./profiles/common/setup.bash"

##########################################################################################
