#!/bin/bash -x

# fail on error
set -e
set -o pipefail

##########################################################################################
BUILD_PROFILE=${BUILD_PROFILE:-"$(basename "$(dirname "${BASH_SOURCE[0]}")")"}
BASE_BUILD_PROFILE=${1:-"common"}
source "$(dirname "${BASH_SOURCE[0]}")/../${BASE_BUILD_PROFILE}/setup.bash" "${@:2}" ""


##########################################################################################

# undefined
UBSAN_OPTIONS=print_stacktrace=1:halt_on_error=1:suppressions=${CCWS_BUILD_PROFILE_DIR}/undefined.supp
export UBSAN_OPTIONS

# leaks
LSAN_OPTIONS=suppressions=${CCWS_BUILD_PROFILE_DIR}/leak.supp
export LSAN_OPTIONS

# address sanitizer
#
# ---
# verify_asan_link_order=0
# Suppress "ASan runtime does not come first in initial library list; you
# should either link runtime to your application or
# manually preload it with LD_PRELOAD."
# The error appears when trying to use a sanitized shared library (e.g., a
# plugin) used by an unsanitized executable
# (https://github.com/google/sanitizers/wiki/AddressSanitizer):
# ```
# Q: I've built my shared library with ASan. Can I run it with unsanitized executable?
# A: Yes! You'll need to build your library with dynamic version of ASan and
# then run executable with LD_PRELOAD=path/to/asan/runtime/lib.
# ```
# Using `verify_asan_link_order=0` should be safe in many (most?) cases, see
# https://github.com/google/sanitizers/issues/796
#
# Does not work with GCC 7.X
#ASAN_OPTIONS=verify_asan_link_order=0
#export ASAN_OPTIONS
#
# LD_PRELOAD should not be set here, but rather in an execution profile, e.g.,
# see `address_sanitizer`.
