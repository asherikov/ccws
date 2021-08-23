#!/bin/bash -x

# fail on error
set -e
set -o pipefail

##########################################################################################

PROFILE="$(basename "$(dirname "${BASH_SOURCE[0]}")")"
source "./profiles/common/setup.bash"

##########################################################################################

# undefined
UBSAN_OPTIONS=print_stacktrace=1:halt_on_error=1:suppressions=${CCWS_PROFILE_DIR}/undefined.supp
export UBSAN_OPTIONS

# leaks
LSAN_OPTIONS=suppressions=${CCWS_PROFILE_DIR}/leak.supp
export LSAN_OPTIONS

