#!/bin/bash -x
# shellcheck disable=SC1090

# fail on error
set -e
set -o pipefail

##########################################################################################

CCWS_PROFILE="cross_raspberry_pi"
export CCWS_PROFILE

source "./profiles/common/setup.bash"
set -e

CCWS_SYSROOT="${CCWS_PROFILE_DIR}/sysroot"
export CCWS_SYSROOT
mkdir -p "${CCWS_SYSROOT}"

# host root in emulation
CCWS_HOST_ROOT=/host-rootfs/
export CCWS_HOST_ROOT


##########################################################################################
# target triple
#
CCWS_TRIPLE_ARCH=arm
CCWS_TRIPLE_SYS=linux
CCWS_TRIPLE_ABI=gnueabihf

CCWS_TRIPLE=${CCWS_TRIPLE_ARCH}-${CCWS_TRIPLE_SYS}-${CCWS_TRIPLE_ABI}

export CCWS_TRIPLE CCWS_TRIPLE_ARCH CCWS_TRIPLE_SYS CCWS_TRIPLE_ABI


##########################################################################################
# compiler paths
#
CCWS_COMPILER_ROOT=/opt/cross-pi-gcc/

CXX=${CCWS_COMPILER_ROOT}/bin/arm-linux-gnueabihf-g++
CC=${CCWS_COMPILER_ROOT}/bin/arm-linux-gnueabihf-gcc
export CXX CC

PATH=${CCWS_COMPILER_ROOT}/bin/:${CCWS_HOST_ROOT}/usr/bin:${CCWS_PROFILE_DIR}/bin:/bin:${PATH}
LD_LIBRARY_PATH=${CCWS_HOST_ROOT}/usr/lib:${LD_LIBRARY_PATH}

export CCWS_COMPILER_ROOT PATH LD_LIBRARY_PATH


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
ROS_PYTHON_VERSION=3
export ROS_PYTHON_VERSION


##########################################################################################
# colcon
#

# skip tests
#COLCON_BUILD_ARGS="${COLCON_BUILD_ARGS} --catkin-skip-building-tests"
#export COLCON_BUILD_ARGS


##########################################################################################
# proot
#

CCWS_PROOT_ARGS="--rootfs=${CCWS_SYSROOT}"
# workspace and compiler
CCWS_PROOT_ARGS+=" --bind=${CCWS_WORKSPACE_DIR}"
CCWS_PROOT_ARGS+=" --bind=${CCWS_PROFILE_DIR}/cross-pi-gcc:${CCWS_COMPILER_ROOT}"
# rosdep stuff
CCWS_PROOT_ARGS+=" --bind=${HOME}/.ros/rosdep/:${ROS_HOME}/rosdep"
CCWS_PROOT_ARGS+=" --bind=/etc/ros/rosdep/"
# bind mounting of /bin/ breaks stuff for some reason
CCWS_PROOT_ARGS+=" --bind=/bin/true"
CCWS_PROOT_ARGS+=" --bind=/bin/false"
CCWS_PROOT_ARGS+=" --bind=/bin/pwd"
CCWS_PROOT_ARGS+=" --bind=/bin/echo"
CCWS_PROOT_ARGS+=" --bind=/bin/ls"
CCWS_PROOT_ARGS+=" --bind=/bin/ln"
CCWS_PROOT_ARGS+=" --bind=/bin/sh"
CCWS_PROOT_ARGS+=" --bind=/bin/rm"
CCWS_PROOT_ARGS+=" --bind=/bin/bash"
CCWS_PROOT_ARGS+=" --bind=/bin/uname"
CCWS_PROOT_ARGS+=" --bind=/bin/mktemp"
CCWS_PROOT_ARGS+=" --bind=/usr/bin/env"
CCWS_PROOT_ARGS+=" --bind=/usr/bin/perl"
CCWS_PROOT_ARGS+=" --bind=/usr/bin/make"
CCWS_PROOT_ARGS+=" --bind=/usr/bin/cmake"
# python bindings
CCWS_PROOT_ARGS+=" --bind=/usr/bin/python"
CCWS_PROOT_ARGS+=" --bind=/usr/bin/python3"
CCWS_PROOT_ARGS+=" $(find /usr/lib/ -maxdepth 1 -name "python*" | sed "s/^/--bind=/" | paste -s -d ' ')"
# qemu
CCWS_PROOT_ARGS+=" --qemu=qemu-${CCWS_TRIPLE_ARCH}"
export CCWS_PROOT_ARGS

