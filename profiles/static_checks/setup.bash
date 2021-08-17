#!/bin/bash -x

# fail on error
set -e
set -o pipefail

##########################################################################################

if [ -z "${CCWS_PROFILE}" ]
then
    CCWS_PROFILE="static_checks"
    export CCWS_PROFILE
fi

source "./profiles/common/setup.bash"


##########################################################################################
# global exceptions
#

CCWS_STATIC_PATH_EXCEPTIONS=""
export CCWS_STATIC_PATH_EXCEPTIONS


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
