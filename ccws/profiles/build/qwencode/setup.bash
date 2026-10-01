#!/bin/bash -x

# fail on error
set -e
set -o pipefail

##########################################################################################
CCWS_PRIMARY_BUILD_PROFILE=${CCWS_PRIMARY_BUILD_PROFILE:-"$(basename "$(dirname "${BASH_SOURCE[0]}")")"}
source "$(dirname "${BASH_SOURCE[0]}")/../codebase_memory_mcp/setup.bash" "${@:2}" ""

NPM_CONFIG_PREFIX=${CCWS_TOOLS_DIR}
export NPM_CONFIG_PREFIX

QWEN_CODE_SYSTEM_SETTINGS_PATH=${BUILD_PROFILES_DIR}/qwencode/global/settings.json
QWEN_HOME=${BUILD_PROFILES_DIR}/qwencode/user
QWEN_RUNTIME_DIR="${CCWS_BUILD_DIR}"
export QWEN_CODE_SYSTEM_SETTINGS_PATH QWEN_HOME QWEN_RUNTIME_DIR
##########################################################################################
