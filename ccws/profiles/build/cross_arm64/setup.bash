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

# 14 currently fails on rapidjson
# https://github.com/Tencent/rapidjson/issues/2277
# https://bugs.launchpad.net/ubuntu/+source/rapidjson/+bug/2073996
CCWS_GCC_VERSION=13

CXX=${CCWS_BUILD_ROOTFS}/usr/bin/${CCWS_TRIPLE}-g++-${CCWS_GCC_VERSION}
CC=${CCWS_BUILD_ROOTFS}/usr/bin/${CCWS_TRIPLE}-gcc-${CCWS_GCC_VERSION}
export CXX CC

export CCWS_GCC_VERSION
