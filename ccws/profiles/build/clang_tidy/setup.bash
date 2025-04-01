#!/bin/bash -x

# fail on error
set -e
set -o pipefail

##########################################################################################
CCWS_PRIMARY_BUILD_PROFILE=${CCWS_PRIMARY_BUILD_PROFILE:-"$(basename "$(dirname "${BASH_SOURCE[0]}")")"}
source "$(dirname "${BASH_SOURCE[0]}")/../${1:-"static_checks"}/setup.bash" "${@:2}" ""

CCWS_STATIC_DIR_EXCEPTIONS="${CCWS_STATIC_DIR_EXCEPTIONS}$(ccws_read_exceptions paths)"
##########################################################################################
