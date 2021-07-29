#!/bin/bash -x
# shellcheck disable=SC1090

# fail on error
set -e
set -o pipefail

##########################################################################################

CCW_PROFILE="cross_raspberry_pi"
export CCW_PROFILE

source "./profiles/common/setup.bash"
set -e

CCW_SYSROOT="${CCW_PROFILE_DIR}/sysroot"
export CCW_SYSROOT
mkdir -p "${CCW_SYSROOT}"

# host root in emulation
CCW_HOST_ROOT=/host-rootfs/
export CCW_HOST_ROOT


##########################################################################################
# target triple
#
CCW_TRIPLE_ARCH=arm
CCW_TRIPLE_SYS=linux
CCW_TRIPLE_ABI=gnueabihf

CCW_TRIPLE=${CCW_TRIPLE_ARCH}-${CCW_TRIPLE_SYS}-${CCW_TRIPLE_ABI}

export CCW_TRIPLE CCW_TRIPLE_ARCH CCW_TRIPLE_SYS CCW_TRIPLE_ABI


##########################################################################################
# compiler paths
#
CCW_COMPILER_ROOT=/opt/cross-pi-gcc/

CXX=${CCW_COMPILER_ROOT}/bin/arm-linux-gnueabihf-g++
CC=${CCW_COMPILER_ROOT}/bin/arm-linux-gnueabihf-gcc
export CXX CC

PATH=${CCW_COMPILER_ROOT}/bin/:${CCW_HOST_ROOT}/usr/bin:${CCW_PROFILE_DIR}/bin:/bin:${PATH}
LD_LIBRARY_PATH=${CCW_HOST_ROOT}/usr/lib:${LD_LIBRARY_PATH}

export CCW_COMPILER_ROOT PATH LD_LIBRARY_PATH


##########################################################################################
# system package search parameters
#

# needed for non-proot crosscompilation
#PKG_CONFIG_SYSROOT_DIR=${CCW_SYSROOT}
#PKG_CONFIG_PATH="${PKG_CONFIG_PATH}:${CCW_SYSROOT}/usr/lib/pkgconfig:${CCW_SYSROOT}/usr/lib/${CCW_TRIPLE}/pkgconfig:${CCW_SYSROOT}/usr/share/pkgconfig"
#PKG_CONFIG_SYSROOT_DIR=/
PKG_CONFIG_PATH="${PKG_CONFIG_PATH}:/usr/lib/pkgconfig:/usr/lib/${CCW_TRIPLE}/pkgconfig:/usr/share/pkgconfig"

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

CCW_PROOT_ARGS="--rootfs=${CCW_SYSROOT}"
# workspace and compiler
CCW_PROOT_ARGS+=" --bind=${CCW_WORKSPACE_DIR}"
CCW_PROOT_ARGS+=" --bind=${CCW_PROFILE_DIR}/cross-pi-gcc:${CCW_COMPILER_ROOT}"
# rosdep stuff
CCW_PROOT_ARGS+=" --bind=${HOME}/.ros/rosdep/:${ROS_HOME}/rosdep"
CCW_PROOT_ARGS+=" --bind=/etc/ros/rosdep/"
# bind mounting of /bin/ breaks stuff for some reason
CCW_PROOT_ARGS+=" --bind=/bin/true"
CCW_PROOT_ARGS+=" --bind=/bin/false"
CCW_PROOT_ARGS+=" --bind=/bin/pwd"
CCW_PROOT_ARGS+=" --bind=/bin/echo"
CCW_PROOT_ARGS+=" --bind=/bin/ls"
CCW_PROOT_ARGS+=" --bind=/bin/ln"
CCW_PROOT_ARGS+=" --bind=/bin/sh"
CCW_PROOT_ARGS+=" --bind=/bin/rm"
CCW_PROOT_ARGS+=" --bind=/bin/bash"
CCW_PROOT_ARGS+=" --bind=/bin/uname"
CCW_PROOT_ARGS+=" --bind=/bin/mktemp"
CCW_PROOT_ARGS+=" --bind=/usr/bin/env"
CCW_PROOT_ARGS+=" --bind=/usr/bin/perl"
CCW_PROOT_ARGS+=" --bind=/usr/bin/make"
CCW_PROOT_ARGS+=" --bind=/usr/bin/cmake"
# python bindings
CCW_PROOT_ARGS+=" --bind=/usr/bin/python"
CCW_PROOT_ARGS+=" --bind=/usr/bin/python3"
CCW_PROOT_ARGS+=" $(find /usr/lib/ -maxdepth 1 -name "python*" | sed "s/^/--bind=/" | paste -s -d ' ')"
# qemu
CCW_PROOT_ARGS+=" --qemu=qemu-${CCW_TRIPLE_ARCH}"
export CCW_PROOT_ARGS

