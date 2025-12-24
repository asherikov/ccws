#!/usr/bin/env bash

set -Ee
set -o pipefail

# Function to extract debug information from a file
extract_debug_info() {
    local FILE_PATH="${1}"
    local OBJCOPY_PREFIX="${2:-}"  # Optional prefix for objcopy

    if [[ "${FILE_PATH}" == *.debug ]]; then
        return 0
    fi

    if ! objdump -h "${FILE_PATH}" >/dev/null 2>&1 || ! objdump -h "${FILE_PATH}" | grep -q "\.debug"; then
        return 0
    fi

    echo "Processing ${FILE_PATH}"
    local FILE
    FILE="$(basename "${FILE_PATH}")"

    pushd "$(dirname "${FILE_PATH}")" > /dev/null
    # https://stackoverflow.com/questions/866721/how-to-generate-gcc-debug-symbol-outside-the-build-target
    "${OBJCOPY_PREFIX}objcopy" --only-keep-debug "${FILE}" "${FILE}.debug"
    "${OBJCOPY_PREFIX}objcopy" --strip-debug "${FILE}"
    "${OBJCOPY_PREFIX}objcopy" --add-gnu-debuglink="${FILE}.debug" "${FILE}"
    chmod 444 "${FILE}.debug"
    popd > /dev/null
}

if [ $# -lt 1 ] || [ $# -gt 2 ]; then
    echo "Usage: $0 <directory> [arch_triplet]" >&2
    echo "  directory: Directory to process for debug information" >&2
    echo "  arch_triplet: Optional target architecture triplet (e.g., x86_64-linux-gnu)" >&2
    exit 1
fi

SEARCH_DIR="${1}"
ARCH_TRIPLET="${2:-}"  # Optional architecture triplet

# Set objcopy prefix based on architecture triplet if provided
OBJCOPY_PREFIX=""
if [ -n "${ARCH_TRIPLET}" ]; then
    OBJCOPY_PREFIX="${ARCH_TRIPLET}-"
fi

if [ ! -d "${SEARCH_DIR}" ]; then
    echo "Error: Directory '${SEARCH_DIR}' does not exist" >&2
    exit 1
fi

# Process object files
find "${SEARCH_DIR}" -not -path "*/.git/*" -type f \( -name "*.o" -o -name "*.so" -o -name "*.so.*" \) -print0 | while IFS= read -r -d '' OBJ_FILE; do
    extract_debug_info "${OBJ_FILE}" "${OBJCOPY_PREFIX}"
done

# Process executable files
find "${SEARCH_DIR}" -not -path "*/.git/*" -type f -executable -exec file {} \; 2>/dev/null | \
grep -E ":.*(executable|shared object)" | \
grep -v ": data" | \
cut -d: -f1 | \
sort -u | \
while read -r EXE_FILE; do
    # Skip .o and .so files as they were already processed
    if [[ "${EXE_FILE}" =~ \.(o|so)$ ]]; then
        continue
    fi

    extract_debug_info "${EXE_FILE}" "${OBJCOPY_PREFIX}"
done
