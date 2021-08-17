#!/bin/bash -x
# shellcheck disable=SC1090

# fail on error
set -e
set -o pipefail

##########################################################################################

CCWS_PROFILE="cross_jetson_nano"
export CCWS_PROFILE

CCWS_SYSROOT="$(dirname ${BASH_SOURCE})/sysroot"
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

PATH=${CCWS_HOST_ROOT}/usr/bin:${CCWS_PROOT_BIN}:/bin:${PATH}
LD_LIBRARY_PATH=${CCWS_HOST_ROOT}/usr/lib:${LD_LIBRARY_PATH}

export PATH LD_LIBRARY_PATH


##########################################################################################
# system package search parameters
#

# needed for non-proot crosscompilation
#PKG_CONFIG_SYSROOT_DIR=${CCWS_SYSROOT}
#PKG_CONFIG_PATH="${PKG_CONFIG_PATH}:${CCWS_SYSROOT}/usr/lib/pkgconfig:${CCWS_SYSROOT}/usr/lib/${CCWS_TRIPLE}/pkgconfig:${CCWS_SYSROOT}/usr/share/pkgconfig"
#PKG_CONFIG_SYSROOT_DIR=/
PKG_CONFIG_PATH="${PKG_CONFIG_PATH}:/usr/lib/pkgconfig:/usr/lib/${CCWS_TRIPLE}/pkgconfig:/usr/share/pkgconfig"

export PKG_CONFIG_SYSROOT_DIR PKG_CONFIG_PATH


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


##########################################################################################
# proot
#
CCWS_PROOT_ARGS=--qemu="qemu-${CCWS_TRIPLE_ARCH}"
export CCWS_PROOT_ARGS
