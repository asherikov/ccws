#!/bin/bash -x

# fail on error
set -e
set -o pipefail

##########################################################################################
CCWS_PRIMARY_BUILD_PROFILE=${CCWS_PRIMARY_BUILD_PROFILE:-"$(basename "$(dirname "${BASH_SOURCE[0]}")")"}

CROSS_PROFILE="$(basename "$(dirname "${BASH_SOURCE[0]}")")"
export CROSS_PROFILE

# target triple
CCWS_TRIPLE_ARCH=arm
CCWS_TRIPLE_SYS=linux
CCWS_TRIPLE_ABI=gnueabihf

# setup common
source "$(dirname "${BASH_SOURCE[0]}")/../${1:-"common"}/setup.bash" "${@:2}" ""


# https://docs.ros.org/en/eloquent/Tutorials/Cross-compilation.html
# https://github.com/ros2/python_cmake_module/blob/humble/cmake/Modules/FindPythonExtra.cmake
# https://github.com/ros2/rosidl_python/issues/111
PYTHON_SOABI=cpython-310-${CCWS_TRIPLE}
export PYTHON_SOABI

ROS_OS_OVERRIDE=debian:10:buster
export ROS_OS_OVERRIDE


##########################################################################################
# compiler paths
#
CCWS_COMPILER_ROOT_HOST="${CCWS_SYSROOT_DATA}/cross-pi-gcc"
CCWS_COMPILER_ROOT_TARGET=/opt/cross-pi-gcc/

export CCWS_COMPILER_ROOT_HOST CCWS_COMPILER_ROOT_TARGET

CCWS_GCC_VERSION=8
export CCWS_GCC_VERSION

CXX=${CCWS_COMPILER_ROOT_TARGET}/bin/${CCWS_TRIPLE}-g++
CC=${CCWS_COMPILER_ROOT_TARGET}/bin/${CCWS_TRIPLE}-gcc
export CXX CC

