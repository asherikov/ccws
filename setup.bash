#!/bin/bash

WORKSPACE_DIR=$(dirname ${BASH_SOURCE})
PROFILE=$1

if [ -z "${PROFILE}" ];
then
    PROFILE="reldebug"
fi

source ${WORKSPACE_DIR}/profiles/${PROFILE}/setup.bash

# ignore errors to prevent session termination
set +e
