#!/bin/bash -x

# fail on error
set -e
set -o pipefail

##########################################################################################
BUILD_PROFILE=${BUILD_PROFILE:-"$(basename "$(dirname "${BASH_SOURCE[0]}")")"}
source "$(dirname "${BASH_SOURCE[0]}")/../${1:-"common"}/setup.bash" "${@:2}" ""

##########################################################################################

# thread
# not supported on Linux (yet?): ignore_noninstrumented_modules=1:ignore_interceptors_accesses=1
TSAN_OPTIONS=second_deadlock_stack=1:suppressions=${CCWS_BUILD_PROFILE_DIR}/thread.supp:history_size=7:halt_on_error=1
export TSAN_OPTIONS

