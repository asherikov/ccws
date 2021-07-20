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

PATH=/host-rootfs/usr/bin:${CCW_PROFILE_DIR}/bin:/bin:${PATH}
LD_LIBRARY_PATH=/host-rootfs/usr/lib:${LD_LIBRARY_PATH}

export CCW_COMPILER_ROOT PATH LD_LIBRARY_PATH


##########################################################################################
# system package search parameters
#
PKG_CONFIG_SYSROOT_DIR=${CCW_SYSROOT}
PKG_CONFIG_PATH="${PKG_CONFIG_PATH}:${CCW_SYSROOT}/usr/lib/pkgconfig:${CCW_SYSROOT}/usr/lib/${CCW_TRIPLE}/pkgconfig:${CCW_SYSROOT}/usr/share/pkgconfig"

export PKG_CONFIG_SYSROOT_DIR PKG_CONFIG_PATH


##########################################################################################
# ROS
#

ROS_PYTHON_VERSION=3
export ROS_PYTHON_VERSION
