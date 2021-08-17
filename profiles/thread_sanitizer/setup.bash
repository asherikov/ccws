#!/bin/bash -x

# fail on error
set -e
set -o pipefail

##########################################################################################

CCWS_PROFILE="thread_sanitizer"
export CCWS_PROFILE

source "./profiles/common/setup.bash"

##########################################################################################
set +e
