#!/bin/bash -x
# shellcheck disable=SC1090

# fail on error
set -e
set -o pipefail

##########################################################################################

CCW_ROS_DISTRO="melodic"
export CCW_ROS_DISTRO
CCW_PROFILE="reldebug"
export CCW_PROFILE

source "./profiles/common/setup.bash"

##########################################################################################
set +e
