#!/bin/bash -x

# fail on error
set -e
set -o pipefail

##########################################################################################
CCWS_PRIMARY_BUILD_PROFILE=${CCWS_PRIMARY_BUILD_PROFILE:-"$(basename "$(dirname "${BASH_SOURCE[0]}")")"}
# shellcheck disable=SC2276
CCWS_@@BUILD_PROFILE@@_BASE_PROFILE="${1:-"@@PARENT_BUILD_PROFILE@@"}"
export CCWS_@@BUILD_PROFILE@@_BASE_PROFILE
source "$(dirname "${BASH_SOURCE[0]}")/../${CCWS_@@BUILD_PROFILE@@_BASE_PROFILE}/setup.bash" "${@:2}" ""

