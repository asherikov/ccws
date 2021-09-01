#!/bin/bash -x

# fail on error
set -e
set -o pipefail

##########################################################################################
BUILD_PROFILE=${1:-"$(basename "$(dirname "${BASH_SOURCE[0]}")")"}
source "$(dirname "${BASH_SOURCE[0]}")/../common/setup.bash"


##########################################################################################

# undefined
UBSAN_OPTIONS=print_stacktrace=1:halt_on_error=1:suppressions=${CCWS_BUILD_PROFILE_DIR}/undefined.supp
export UBSAN_OPTIONS

# leaks
LSAN_OPTIONS=suppressions=${CCWS_BUILD_PROFILE_DIR}/leak.supp
export LSAN_OPTIONS

