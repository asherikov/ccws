#!/bin/bash -x

set -e
set -o pipefail

CCWS_PRIMARY_BUILD_PROFILE=${CCWS_PRIMARY_BUILD_PROFILE:-"$(basename "$(dirname "${BASH_SOURCE[0]}")")"}
CCWS_COVERAGE_BASE_PROFILE=${1:-"reldebug}"}
export CCWS_COVERAGE_BASE_PROFILE
source "$(dirname "${BASH_SOURCE[0]}")/../${CCWS_COVERAGE_BASE_PROFILE}/setup.bash" "${@:2}" ""

# enables coverage reports in test targets, see make/test.mk
CCWS_COVERAGE=on
# path patterns excluded from coverage reports
CCWS_COVERAGE_EXCLUDE=${CCWS_COVERAGE_EXCLUDE:-3rdparty}
export CCWS_COVERAGE_EXCLUDE
