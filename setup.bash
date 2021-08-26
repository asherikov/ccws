#!/bin/bash

WORKSPACE_DIR=$(dirname "${BASH_SOURCE[0]}")
PROFILES_DIR="${WORKSPACE_DIR}/profiles/"

if [ -z "${BUILD_PROFILE}" ];
then
    BUILD_PROFILE="reldebug"
fi

if [ $# -gt 0 ]
then
    BUILD_PROFILE=$1
    shift
fi

SETUP_SCRIPT="${PROFILES_DIR}/build/${BUILD_PROFILE}/setup.bash"

if [ -f "${SETUP_SCRIPT}" ]
then
    source "${SETUP_SCRIPT}";
    if [ -t 0 ];
    then
        # ignore errors to prevent session termination if interactive
        set +e
    fi

    # load 'test' exec profile if not overriden explicitly
    if [ $# -eq 0 ]
    then
        if [ -n "${EXEC_PROFILE}" ]
        then
            SETUP_SCRIPT="${PROFILES_DIR}/build/${EXEC_PROFILE}/setup.bash"
        else
            SETUP_SCRIPT="${PROFILES_DIR}/build/test/setup.bash"
        fi

        if [ -f "${SETUP_SCRIPT}" ]
        then
            source "${SETUP_SCRIPT}";
            if [ -t 0 ];
            then
                # ignore errors to prevent session termination if interactive
                set +e
            fi
        else
            ERROR="Cannot load default execution profile: '${SETUP_SCRIPT}'"
        fi
    else
        while [ $# -gt 0 ]
        do
            SETUP_SCRIPT="${PROFILES_DIR}/exec/$1/setup.bash"

            if [ -f "${SETUP_SCRIPT}" ]
            then
                source "${SETUP_SCRIPT}";
                if [ -t 0 ];
                then
                    # ignore errors to prevent session termination if interactive
                    set +e
                fi
            else
                ERROR="Unknown execution profile: '$1'"
                break
            fi

            shift
        done
    fi
else
    ERROR="Unknown build profile: '${BUILD_PROFILE}'"
fi

if [ -n "${ERROR}" ]
then
    echo "${ERROR}"
    false
fi

