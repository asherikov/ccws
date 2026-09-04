#!/bin/bash -x

# fail on error
set -e
set -o pipefail

##########################################################################################
CCWS_PRIMARY_BUILD_PROFILE=${CCWS_PRIMARY_BUILD_PROFILE:-"$(basename "$(dirname "${BASH_SOURCE[0]}")")"}
source "$(dirname "${BASH_SOURCE[0]}")/../${1:-"common"}/setup.bash" "${@:2}" ""

##########################################################################################
# codebase-memory-mcp tool installation
CBM_DOWNLOAD_URL='https://github.com/DeusData/codebase-memory-mcp/releases/latest/download'
export CBM_DOWNLOAD_URL

case "$(uname -m)" in
    x86_64) CBM_ARCH=amd64 ;;
    aarch64) CBM_ARCH=arm64 ;;
    *) echo "unsupported arch"; exit 1 ;;
esac

CBM_ARCHIVE="codebase-memory-mcp-linux-${CBM_ARCH}-portable.tar.gz"
export CBM_ARCHIVE
##########################################################################################
