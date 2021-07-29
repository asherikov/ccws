#!/bin/bash -x
# shellcheck disable=SC1090

# fail on error
set -e
set -o pipefail

##########################################################################################

CCWS_PROFILE="reldebug"
export CCWS_PROFILE

source "./profiles/common/setup.bash"

##########################################################################################
set +e
