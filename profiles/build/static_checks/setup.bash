#!/bin/bash -x

# fail on error
set -e
set -o pipefail

##########################################################################################
BUILD_PROFILE=${BUILD_PROFILE:-"$(basename "$(dirname "${BASH_SOURCE[0]}")")"}
source "$(dirname "${BASH_SOURCE[0]}")/../${1:-"common"}/setup.bash" "${@:2}" ""


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
# - SC1091: Not following: ...: openBinaryFile: does not exist (No such file or
# directory)
# - SC2016: Expressions don't expand in single quotes, use double quotes for
# that. [this is usually intentional]
# - SC2034: XXX appears unused. Verify it or export it. [variables are often
# exported from other scripts]
CCWS_SHELLCHECK_EXCEPTIONS="--exclude=SC2001,SC1090,SC1091,SC2016,SC2034"
export CCWS_SHELLCHECK_EXCEPTIONS


##########################################################################################
# catkin lint
#

CCWS_CATKIN_LINT_EXCEPTIONS="\
--ignore package_path_name \
--ignore unsorted_list \
--ignore description_meaningless \
--ignore critical_var_append \
--ignore no_catkin_component \
--ignore description_boilerplate \
--ignore uninstalled_script \
--ignore ambiguous_include_path \
--ignore unknown_package \
--ignore subproject \
--ignore duplicate_cmd \
--ignore env_var"
export CCWS_CATKIN_LINT_EXCEPTIONS

