#!/bin/bash

WORKSPACE_DIR=$(dirname "${BASH_SOURCE[0]}" | xargs realpath)
PROFILES_DIR="${WORKSPACE_DIR}/ccws/profiles/"

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
    source "${SETUP_SCRIPT}" "";
    if [ -t 0 ];
    then
        # ignore errors to prevent session termination if interactive
        set +e
    fi


    if [ $# -eq 0 ]
    then
        # load 'test' exec profile if not overriden explicitly
        if [ -z "${EXEC_PROFILE}" ]
        then
            EXEC_PROFILE="test"
        fi
    else
        # comman line parameters override environment

        EXEC_PROFILE="$1"
        shift

        while [ $# -gt 0 ]
        do
            EXEC_PROFILE="$1 ${EXEC_PROFILE}"
            shift
        done
    fi


    # normalize
    EXEC_PROFILE=$(echo "${EXEC_PROFILE}" | sed -e "s/^ *//"  -e "s/ *$//"  -e "s/ \+/ /g"  -e "s/ /\\n/g" | grep -v "^common$" | grep -v "^vendor$" | paste -d ' ' -s)
    # prepend common and append vendor specific parameters
    EXEC_PROFILE="common ${EXEC_PROFILE}"
    if [ -f "${PROFILES_DIR}/exec/vendor/setup.bash" ]
    then
        EXEC_PROFILE="${EXEC_PROFILE} vendor"
    fi
    EXEC_PROFILE=$(echo "${EXEC_PROFILE}" | sed -e "s/ \+/ /g")


    for PROFILE in ${EXEC_PROFILE};
    do
        SETUP_SCRIPT="${PROFILES_DIR}/exec/${PROFILE}/setup.bash"

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
    done
else
    ERROR="Unknown build profile: '${BUILD_PROFILE}'"
fi

if [ -n "${ERROR}" ]
then
    echo "${ERROR}"
    false
fi

