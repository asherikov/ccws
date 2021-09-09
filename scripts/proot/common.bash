#!/bin/bash
set -e

# suppress annoying ld warnings
CCWS_PROOT_ARGS="--bind='/dev/null:/etc/ld.so.preload'"

PATH="${CCWS_BUILD_ROOTFS}/usr/bin:${PATH}"
LD_LIBRARY_PATH=${CCWS_BUILD_ROOTFS}/usr/lib:${LD_LIBRARY_PATH}

# non-native build
if [ "${CCWS_TRIPLE_ARCH}" != "$(uname -m)" ]
then
    CCWS_PROOT_ARGS+=" --qemu=qemu-${CCWS_TRIPLE_ARCH}"
fi

if [ -n "${CCWS_COMPILER_ROOT_TARGET}" ]
then
    CCWS_PROOT_ARGS+=" --bind=${CCWS_COMPILER_ROOT_HOST}:${CCWS_COMPILER_ROOT_TARGET}"
    PATH="${CCWS_COMPILER_ROOT_TARGET}/bin/:${PATH}"
fi

export PATH LD_LIBRARY_PATH CCWS_PROOT_ARGS

