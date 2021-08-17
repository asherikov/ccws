#!/bin/bash -x

# fail on error
set -e
set -o pipefail

##########################################################################################

CCWS_PROFILE="cross_jetson_nano"
export CCWS_PROFILE

CCWS_SYSROOT=$(dirname "${BASH_SOURCE[0]}")/sysroot
export CCWS_SYSROOT

# host root in emulation
CCWS_HOST_ROOT=/host-rootfs/
export CCWS_HOST_ROOT


##########################################################################################
# target triple
#
CCWS_TRIPLE_ARCH=aarch64
CCWS_TRIPLE_SYS=linux
CCWS_TRIPLE_ABI=gnu

CCWS_TRIPLE=${CCWS_TRIPLE_ARCH}-${CCWS_TRIPLE_SYS}-${CCWS_TRIPLE_ABI}

export CCWS_TRIPLE CCWS_TRIPLE_ARCH CCWS_TRIPLE_SYS CCWS_TRIPLE_ABI


##########################################################################################
# setup common
#

source "./profiles/common/setup.bash"


##########################################################################################
# compiler paths
#
CCWS_GCC_VERSION=8

CXX=${CCWS_HOST_ROOT}/usr/bin/${CCWS_TRIPLE}-g++-${CCWS_GCC_VERSION}
CC=${CCWS_HOST_ROOT}/usr/bin/${CCWS_TRIPLE}-gcc-${CCWS_GCC_VERSION}
export CXX CC

PATH=${CCWS_PROOT_BIN}:/bin:${PATH}
export PATH


##########################################################################################
# system package search parameters
#

PKG_CONFIG_PATH="${PKG_CONFIG_PATH}:/usr/lib/pkgconfig:/usr/lib/${CCWS_TRIPLE}/pkgconfig:/usr/share/pkgconfig"
export PKG_CONFIG_PATH


##########################################################################################
# ROS
#

#ROS_PYTHON_VERSION=3
#export ROS_PYTHON_VERSION


##########################################################################################
# colcon
#

# skip tests
#COLCON_BUILD_ARGS="${COLCON_BUILD_ARGS} --catkin-skip-building-tests"
#export COLCON_BUILD_ARGS


##########################################################################################
# CUDA
#

CCWS_CUDA_VERSION=10.2
CUDA_INC_PATH=/usr/local/cuda-${CCWS_CUDA_VERSION}/targets/${CCWS_TRIPLE_ARCH}-${CCWS_TRIPLE_SYS}/
CUDA_LIB_PATH=/usr/local/cuda-${CCWS_CUDA_VERSION}/targets/${CCWS_TRIPLE_ARCH}-${CCWS_TRIPLE_SYS}/
export CCWS_CUDA_VERSION CUDA_INC_PATH CUDA_LIB_PATH
