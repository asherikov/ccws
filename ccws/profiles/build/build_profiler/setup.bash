#!/bin/bash -x

# fail on error
set -e
set -o pipefail

##########################################################################################
CCWS_PRIMARY_BUILD_PROFILE=${CCWS_PRIMARY_BUILD_PROFILE:-"$(basename "$(dirname "${BASH_SOURCE[0]}")")"}
source "$(dirname "${BASH_SOURCE[0]}")/../common/setup.bash" "${@:2}" ""

##########################################################################################
# compilation caches must not be used in this profile: cached compilations are
# not executed and distort the measurements; 'ccache' and 'buildcache' are
# disabled via the environment, launchers that may be configured by workspace
# extras are overridden in 'toolchain_body.cmake'
export CCACHE_DISABLE=1
export BUILDCACHE_DISABLE=1
