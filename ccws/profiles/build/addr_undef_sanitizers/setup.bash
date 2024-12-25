#!/bin/bash -x

# fail on error
set -e
set -o pipefail

##########################################################################################
CCWS_PRIMARY_BUILD_PROFILE=${CCWS_PRIMARY_BUILD_PROFILE:-"$(basename "$(dirname "${BASH_SOURCE[0]}")")"}
source "$(dirname "${BASH_SOURCE[0]}")/../${1:-"common"}/setup.bash" "${@:2}" ""


##########################################################################################

# https://stackoverflow.com/questions/48267394/what-are-the-valid-sanitizer-suppression-strings-for-gcc

# undefined
UBSAN_OPTIONS=print_stacktrace=1:halt_on_error=1:suppressions=${BUILD_PROFILES_DIR}/addr_undef_sanitizers/undefined.supp
export UBSAN_OPTIONS

# leaks
LSAN_OPTIONS=suppressions=${BUILD_PROFILES_DIR}/addr_undef_sanitizers/leak.supp
export LSAN_OPTIONS

# Suppressions dont work on alloc-dealloc-mismatch for some reason
ASAN_OPTIONS=alloc_dealloc_mismatch=0:new_delete_type_mismatch=0:suppressions=${BUILD_PROFILES_DIR}/addr_undef_sanitizers/address.supp
export ASAN_OPTIONS

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
