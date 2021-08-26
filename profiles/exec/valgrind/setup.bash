#!/bin/bash -x

# fail on error
set -e
set -o pipefail

##########################################################################################

CURRENT_DIR=$(dirname "${BASH_SOURCE[0]}")

CCWS_NODE_LAUNCH_PREFIX="valgrind \
    --tool=memcheck --vgdb=no --error-exitcode=77 --fullpath-after=src/ --gen-suppressions=all --suppressions=${CURRENT_DIR}/valgrind.supp --leak-check=no"
export CCWS_NODE_LAUNCH_PREFIX


##########################################################################################
