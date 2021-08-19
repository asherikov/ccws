#!/bin/bash
set -e

CCWS_PROOT_ARGS=""
PATH="${CCWS_HOST_ROOT}/usr/bin:${PATH}"
LD_LIBRARY_PATH=${CCWS_HOST_ROOT}/usr/lib:${LD_LIBRARY_PATH}

# CCWS_TRIPLE_ARCH is set for native builds as well, CCWS_TRIPLE -- does not
if [ -n "${CCWS_TRIPLE}" ]
then
    CCWS_PROOT_ARGS+=" --qemu=qemu-${CCWS_TRIPLE_ARCH}"
fi

if [ -n "${CCWS_COMPILER_ROOT_TARGET}" ]
then
    CCWS_PROOT_ARGS+=" --bind=${CCWS_COMPILER_ROOT_HOST}:${CCWS_COMPILER_ROOT_TARGET}"
    PATH="${CCWS_COMPILER_ROOT_TARGET}/bin/:${PATH}"
fi

export PATH LD_LIBRARY_PATH CCWS_PROOT_ARGS

