#!/bin/bash -x
# shellcheck disable=SC1090

# fail on error
set -e
set -o pipefail

##########################################################################################

CCWS_PROFILE="thread_sanitizer"
export CCWS_PROFILE

source "./profiles/common/setup.bash"

##########################################################################################
set +e
