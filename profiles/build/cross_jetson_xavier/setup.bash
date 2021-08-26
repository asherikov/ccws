#!/bin/bash -x

# fail on error
set -e
set -o pipefail

##########################################################################################

BUILD_PROFILE="$(basename "$(dirname "${BASH_SOURCE[0]}")")"

CCWS_SYSROOT=$(dirname "${BASH_SOURCE[0]}")/sysroot


##########################################################################################
# target triple
#
CCWS_TRIPLE_ARCH=aarch64
CCWS_TRIPLE_SYS=linux
CCWS_TRIPLE_ABI=gnu


##########################################################################################
# setup common
#

source "$(dirname "${BASH_SOURCE[0]}")/../common/setup.bash"


##########################################################################################
# compiler paths
#
CCWS_GCC_VERSION=8

CXX=${CCWS_HOST_ROOT}/usr/bin/${CCWS_TRIPLE}-g++-${CCWS_GCC_VERSION}
CC=${CCWS_HOST_ROOT}/usr/bin/${CCWS_TRIPLE}-gcc-${CCWS_GCC_VERSION}
export CXX CC


##########################################################################################
# CUDA
#

CCWS_CUDA_VERSION=10.2
CUDA_INC_PATH=/usr/local/cuda-${CCWS_CUDA_VERSION}/targets/${CCWS_TRIPLE_ARCH}-${CCWS_TRIPLE_SYS}/
CUDA_LIB_PATH=/usr/local/cuda-${CCWS_CUDA_VERSION}/targets/${CCWS_TRIPLE_ARCH}-${CCWS_TRIPLE_SYS}/
export CCWS_CUDA_VERSION CUDA_INC_PATH CUDA_LIB_PATH
