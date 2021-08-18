#!/bin/bash -x

# fail on error
set -e
set -o pipefail

##########################################################################################

CCWS_PROFILE="addr_undef_sanitizers"
export CCWS_PROFILE

source "./profiles/common/setup.bash"

##########################################################################################

# undefined
UBSAN_OPTIONS=print_stacktrace=1:halt_on_error=1:suppressions=${CCWS_PROFILE_DIR}/undefined.supp
export UBSAN_OPTIONS

# leaks
LSAN_OPTIONS=suppressions=${CCWS_PROFILE_DIR}/leak.supp
export LSAN_OPTIONS

