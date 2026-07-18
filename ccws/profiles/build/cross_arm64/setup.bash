#!/bin/bash -x

# fail on error
set -e
set -o pipefail

##########################################################################################
BUILD_PROFILE=${BUILD_PROFILE:-"$(basename "$(dirname "${BASH_SOURCE[0]}")")"}

CROSS_PROFILE="$(basename "$(dirname "${BASH_SOURCE[0]}")")"
export CROSS_PROFILE

# target triple
CCWS_TRIPLE_ARCH=aarch64
CCWS_TRIPLE_SYS=linux
CCWS_TRIPLE_ABI=gnu

# host and build distros must match for tis profile
OS_DISTRO_HOST=${OS_DISTRO_BUILD}
export OS_DISTRO_HOST

# setup common
source "$(dirname "${BASH_SOURCE[0]}")/../${1:-"common"}/setup.bash" "${@:2}" ""


##########################################################################################
# compiler paths
#

case "${OS_DISTRO_HOST}" in
    jammy)
        CCWS_GCC_VERSION=12;;
    noble)
        # 14 currently fails on rapidjson
        # https://github.com/Tencent/rapidjson/issues/2277
        # https://bugs.launchpad.net/ubuntu/+source/rapidjson/+bug/2073996
        CCWS_GCC_VERSION=13;;
    resolute)
        # rosdep fails to detect OS in chroot for some reason
        ROS_OS_OVERRIDE=ubuntu:26.04:resolute
        export ROS_OS_OVERRIDE
        CCWS_GCC_VERSION=16;;
esac


CXX=${CCWS_BUILD_ROOTFS}/usr/bin/${CCWS_TRIPLE}-g++-${CCWS_GCC_VERSION}
CC=${CCWS_BUILD_ROOTFS}/usr/bin/${CCWS_TRIPLE}-gcc-${CCWS_GCC_VERSION}
export CXX CC

export CCWS_GCC_VERSION
