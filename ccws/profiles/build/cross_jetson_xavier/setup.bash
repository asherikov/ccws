#!/bin/bash -x

# fail on error
set -e
set -o pipefail

##########################################################################################
CCWS_PRIMARY_BUILD_PROFILE=${CCWS_PRIMARY_BUILD_PROFILE:-"$(basename "$(dirname "${BASH_SOURCE[0]}")")"}

CROSS_PROFILE="$(basename "$(dirname "${BASH_SOURCE[0]}")")"
export CROSS_PROFILE

# target triple
CCWS_TRIPLE_ARCH=aarch64
CCWS_TRIPLE_SYS=linux
CCWS_TRIPLE_ABI=gnu

# setup common
source "$(dirname "${BASH_SOURCE[0]}")/../${1:-"common"}/setup.bash" "${@:2}" ""


##########################################################################################
# compiler paths
#
CCWS_GCC_VERSION=8

CXX=${CCWS_BUILD_ROOTFS}/usr/bin/${CCWS_TRIPLE}-g++-${CCWS_GCC_VERSION}
CC=${CCWS_BUILD_ROOTFS}/usr/bin/${CCWS_TRIPLE}-gcc-${CCWS_GCC_VERSION}
export CXX CC CCWS_GCC_VERSION


##########################################################################################
# CUDA
#

CCWS_CUDA_VERSION=10.2
CUDA_INC_PATH=/usr/local/cuda-${CCWS_CUDA_VERSION}/targets/${CCWS_TRIPLE_ARCH}-${CCWS_TRIPLE_SYS}/
CUDA_LIB_PATH=/usr/local/cuda-${CCWS_CUDA_VERSION}/targets/${CCWS_TRIPLE_ARCH}-${CCWS_TRIPLE_SYS}/
export CCWS_CUDA_VERSION CUDA_INC_PATH CUDA_LIB_PATH
