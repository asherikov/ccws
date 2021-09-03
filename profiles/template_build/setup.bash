#!/bin/bash -x

# fail on error
set -e
set -o pipefail

##########################################################################################
BUILD_PROFILE=${BUILD_PROFILE:-"$(basename "$(dirname "${BASH_SOURCE[0]}")")"}
BASE_BUILD_PROFILE=${1:-"@@BASE_BUILD_PROFILE@@"}
source "$(dirname "${BASH_SOURCE[0]}")/../${BASE_BUILD_PROFILE}/setup.bash" "${@:2}" ""

