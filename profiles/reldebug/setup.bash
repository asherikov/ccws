#!/bin/bash -x

# fail on error
set -e
set -o pipefail

##########################################################################################

PROFILE="$(basename "$(dirname "${BASH_SOURCE[0]}")")"
source "$(dirname "${BASH_SOURCE[0]}")/../common/setup.bash"

##########################################################################################
