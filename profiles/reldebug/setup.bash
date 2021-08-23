#!/bin/bash -x

# fail on error
set -e
set -o pipefail

##########################################################################################

PROFILE="$(basename "$(dirname "${BASH_SOURCE[0]}")")"
source "./profiles/common/setup.bash"

##########################################################################################
