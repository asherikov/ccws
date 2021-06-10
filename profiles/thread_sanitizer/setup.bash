#!/bin/bash -x
# shellcheck disable=SC1090

# fail on error
set -e
set -o pipefail

##########################################################################################

CCW_PROFILE="thread_sanitizer"
export CCW_PROFILE

source "./profiles/common/setup.bash"

##########################################################################################
set +e
