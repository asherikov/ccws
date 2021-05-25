#!/bin/sh

MEMORY_PER_JOB_MB=${1}

JOBS_GUESS_MEMORY=$(($(grep MemAvailable < /proc/meminfo | grep -o '[0-9]*') / 1024 / ${MEMORY_PER_JOB_MB}))
JOBS_GUESS_CPU=$(nproc)

if [ 1 -ge "${JOBS_GUESS_MEMORY}" ]
then
    # use at east one job
    echo 1;
else
    # pick minimal (more restrictive) guess
    if [ "${JOBS_GUESS_CPU}" -ge "${JOBS_GUESS_MEMORY}" ]
    then
        echo "${JOBS_GUESS_MEMORY}";
    else
        echo "${JOBS_GUESS_CPU}";
    fi
fi

