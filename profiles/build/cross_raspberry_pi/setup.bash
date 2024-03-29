#!/bin/bash -x

# fail on error
set -e
set -o pipefail

##########################################################################################
BUILD_PROFILE=${BUILD_PROFILE:-"$(basename "$(dirname "${BASH_SOURCE[0]}")")"}

CCWS_SYSROOT=$(dirname "${BASH_SOURCE[0]}")/sysroot

# target triple
CCWS_TRIPLE_ARCH=arm
CCWS_TRIPLE_SYS=linux
CCWS_TRIPLE_ABI=gnueabihf

# setup common
source "$(dirname "${BASH_SOURCE[0]}")/../${1:-"common"}/setup.bash" "${@:2}" ""


ROS_OS_OVERRIDE=debian:10:buster
export ROS_OS_OVERRIDE


##########################################################################################
# compiler paths
#
CCWS_COMPILER_ROOT_HOST=$(dirname "${BASH_SOURCE[0]}")/cross-pi-gcc
CCWS_COMPILER_ROOT_TARGET=/opt/cross-pi-gcc/

export CCWS_COMPILER_ROOT_HOST CCWS_COMPILER_ROOT_TARGET

CCWS_GCC_VERSION=8
export CCWS_GCC_VERSION

CXX=${CCWS_COMPILER_ROOT_TARGET}/bin/${CCWS_TRIPLE}-g++
CC=${CCWS_COMPILER_ROOT_TARGET}/bin/${CCWS_TRIPLE}-gcc
export CXX CC

