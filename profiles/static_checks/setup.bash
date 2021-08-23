#!/bin/bash -x

# fail on error
set -e
set -o pipefail

##########################################################################################

if [ -z "${PROFILE}" ] # can be used by scan_build profile
then
    PROFILE="$(basename "$(dirname "${BASH_SOURCE[0]}")")"
fi
source "./profiles/common/setup.bash"


##########################################################################################
# global exceptions
#

CCWS_SOURCE_DIR="${CCWS_WORKSPACE_DIR}/src"

# popl.hpp
CCWS_STATIC_DIR_EXCEPTIONS=":${CCWS_SOURCE_DIR}/staticoma/src/"
export CCWS_STATIC_DIR_EXCEPTIONS


##########################################################################################
# shell check
#

# - SC2001: See if you can use ${variable//search/replace} instead. [sed is
# more generic]
# - SC1090: Can't follow non-constant source. Use a directive to specify
# location. [not always possible, included files may not be available]
# - SC2016: Expressions don't expand in single quotes, use double quotes for
# that. [this is usually intentional]
CCWS_SHELLCHECK_EXCEPTIONS="--exclude=SC2001,SC1090,SC2016"
export CCWS_SHELLCHECK_EXCEPTIONS
