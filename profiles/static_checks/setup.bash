#!/bin/bash -x

# fail on error
set -e
set -o pipefail

OVERRIDE_PROFILE=$1

##########################################################################################

if [ -n "${OVERRIDE_PROFILE}" ] # can be used by scan_build profile
then
    PROFILE="${OVERRIDE_PROFILE}"
else
    PROFILE="$(basename "$(dirname "${BASH_SOURCE[0]}")")"
fi
source "./profiles/common/setup.bash"


##########################################################################################
# global exceptions
#

# popl.hpp
CCWS_STATIC_DIR_EXCEPTIONS="${CCWS_STATIC_DIR_EXCEPTIONS}:${CCWS_SOURCE_DIR}/staticoma/src/"
CCWS_STATIC_PKG_EXCEPTIONS="${CCWS_STATIC_PKG_EXCEPTIONS}"
export CCWS_STATIC_DIR_EXCEPTIONS CCWS_STATIC_PKG_EXCEPTIONS


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


##########################################################################################
# catkin lint
#

CCWS_CATKIN_LINT_EXCEPTIONS="\
--ignore package_path_name \
--ignore unsorted_list \
--ignore description_meaningless \
--ignore critical_var_append \
--ignore missing_export_lib \
--ignore no_catkin_component \
--ignore description_boilerplate \
--ignore uninstalled_script \
--ignore ambiguous_include_path \
--ignore unknown_package \
--ignore subproject \
--ignore duplicate_cmd"
export CCWS_CATKIN_LINT_EXCEPTIONS

