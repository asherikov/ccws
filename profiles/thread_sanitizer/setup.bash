#!/bin/bash -x

# fail on error
set -e
set -o pipefail

##########################################################################################

CCWS_PROFILE="thread_sanitizer"
export CCWS_PROFILE

source "./profiles/common/setup.bash"

##########################################################################################

# thread
# not supported on Linux (yet?): ignore_noninstrumented_modules=1:ignore_interceptors_accesses=1
TSAN_OPTIONS=second_deadlock_stack=1:suppressions=${CCWS_PROFILE_DIR}/thread.supp:history_size=7:halt_on_error=1
export TSAN_OPTIONS

