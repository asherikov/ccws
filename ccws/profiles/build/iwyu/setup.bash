#!/bin/bash -x

# fail on error
set -e
set -o pipefail

##########################################################################################
CCWS_PRIMARY_BUILD_PROFILE=${CCWS_PRIMARY_BUILD_PROFILE:-"$(basename "$(dirname "${BASH_SOURCE[0]}")")"}
source "$(dirname "${BASH_SOURCE[0]}")/../${1:-"common"}/setup.bash" "${@:2}" ""

##########################################################################################
# path exceptions of this profile and of the chained profiles, e.g.,
# static_checks, are used to filter the compilation database
CCWS_STATIC_DIR_EXCEPTIONS="${CCWS_STATIC_DIR_EXCEPTIONS}$(ccws_read_exceptions paths)"
export CCWS_STATIC_DIR_EXCEPTIONS

##########################################################################################
# https://github.com/include-what-you-use/include-what-you-use
# mapping files are shipped with the 'iwyu' apt package and are required to
# avoid suggestions to include compiler internals, see
# https://github.com/include-what-you-use/include-what-you-use/blob/master/InstructionsForRunners.md
if [ -z "${CCWS_IWYU_ARGS}" ]
then
    IWYU_MAPPING_DIR=/usr/share/include-what-you-use
    CCWS_IWYU_ARGS=""
    # the intrinsics mapping is versioned after the corresponding compiler,
    # which varies between distributions
    for MAPPING in \
        "${IWYU_MAPPING_DIR}"/gcc.libc.imp \
        "${IWYU_MAPPING_DIR}"/gcc.stl.headers.imp \
        "${IWYU_MAPPING_DIR}"/gcc-*.intrinsics.imp
    do
        if [ -f "${MAPPING}" ]
        then
            CCWS_IWYU_ARGS="${CCWS_IWYU_ARGS} -Xiwyu --mapping_file=${MAPPING}"
        fi
    done
fi
export CCWS_IWYU_ARGS

##########################################################################################
