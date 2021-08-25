#!/bin/bash

WORKSPACE_DIR=$(dirname "${BASH_SOURCE[0]}")
BUILD_PROFILES_DIR="${WORKSPACE_DIR}/profiles/"
PROFILE=$1

if [ -z "${PROFILE}" ];
then
    PROFILE="reldebug"
fi

SETUP_SCRIPT="${BUILD_PROFILES_DIR}/${PROFILE}/setup.bash"

if [ -f "${SETUP_SCRIPT}" ]
then
    source "${SETUP_SCRIPT}";
    if [ -t 0 ];
    then
        # ignore errors to prevent session termination if interactive
        set +e
    fi
else
    echo "Unknown profile: '${PROFILE}'"
    false
fi

