#!/bin/bash -x

set -e
set -o pipefail

CCWS_PRIMARY_BUILD_PROFILE=${CCWS_PRIMARY_BUILD_PROFILE:-"$(basename "$(dirname "${BASH_SOURCE[0]}")")"}
CCWS_NOTESTS_BASE_PROFILE=${1:-"${CCWS_NOTESTS_BASE_PROFILE:-reldebug}"}
export CCWS_PRIMARY_BUILD_PROFILE CCWS_NOTESTS_BASE_PROFILE
source "$(dirname "${BASH_SOURCE[0]}")/../${CCWS_NOTESTS_BASE_PROFILE}/setup.bash" "${@:2}" ""
