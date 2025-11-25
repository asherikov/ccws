#!/usr/bin/env bash

set -e
set -o pipefail

if [ $# -ne 2 ]; then
    echo "Usage: $0 <SOURCE_DIRECTORY> <DESTINATION_DIRECTORY>" >&2
    exit 1
fi

SOURCE_DIR="${1}"
DEST_DIR="${2}"

if [ ! -d "${SOURCE_DIR}" ]; then
    echo "Error: Source directory '${SOURCE_DIR}' does not exist" >&2
    exit 1
fi

mkdir -p "${DEST_DIR}"

# Helper function to determine if a file is a static library (not shared libraries)
is_static_library_file() {
    local FILE="$1"
    local EXT
    EXT="${FILE##*.}"

    case "${EXT}" in
        a|lib)
            # Check if it's an actual static archive library
            local FILE_TYPE
            FILE_TYPE=$(file -b "${FILE}" 2>/dev/null || echo "")
            if [[ "${FILE_TYPE}" == *"archive"* ]] && [[ "${FILE_TYPE}" != *"shared object"* ]]; then
                return 0
            fi
            ;;
    esac
    return 1
}

# Helper function to determine if a file is a header
is_header_file() {
    local FILE="$1"
    local FILENAME
    local EXT
    FILENAME=$(basename "${FILE}")
    EXT="${FILENAME##*.}"

    # Check if file is in an include directory
    if [[ "${FILE}" == *"/include/"* ]] || [[ "${FILE}" == *"/include" ]]; then
        return 0
    fi

    # Check if file extension indicates it's a header
    case "${EXT}" in
        h|hpp|hxx|hh|H|tpp)
            return 0
            ;;
    esac

    return 1
}

# Helper function to determine if a file is a man page
is_man_page() {
    local FILE="$1"
    local FILENAME
    local EXT
    FILENAME=$(basename "${FILE}")
    EXT="${FILENAME##*.}"

    # Only consider files under 'man' directory as man pages
    if [[ "${FILE}" != *"/man/"* ]] && [[ "${FILE}" != *"/man" ]]; then
        return 1
    fi

    # Check if file extension indicates it's a man page
    case "${EXT}" in
        [0-9]|man|md|markdown)
            return 0
            ;;
    esac

    return 1
}

# Find all files and process them based on type and location
find "${SOURCE_DIR}" -type f -print0 | while IFS= read -r -d '' FILE; do
    # Extract relative path
    if [[ "${SOURCE_DIR}" != */ ]]; then
        RELATIVE_PATH=$(printf '%s\n' "${FILE}" | sed "s|^${SOURCE_DIR}/||")
    else
        RELATIVE_PATH=$(printf '%s\n' "${FILE}" | sed "s|^${SOURCE_DIR}||")
    fi

    FILE_DIR=$(dirname "${RELATIVE_PATH}")

    # Get basename to use in case statement
    BASENAME=$(basename "${FILE}")

    # Use case statement to match filenames and extensions and continue on failed checks
    case "${FILE}" in
        *"/include/"*|*"/include")
            # Any file in include directory is treated as a header, continue to process
            ;;
        *".a"|*".lib")
            # Check if it's a static library file (with verification)
            if ! is_static_library_file "${FILE}"; then
                continue
            fi
            ;;
        *"/man/"*|*"/man")
            # Check if it's a man page (location-based)
            if ! is_man_page "${FILE}"; then
                continue
            fi
            ;;
        *.debug|*.md|*.markdown|*.cmake)
            # These files are processed as-is
            ;;
        *)
            # For extension-based matching outside special directories
            EXT="${BASENAME##*.}"
            case "${EXT}" in
                h|hpp|hxx|hh|H|tpp)
                    # Header extensions, continue to process
                    ;;
                man)
                    # Man extension - only if in man directory
                    if [[ "${FILE}" != *"/man/"* ]] && [[ "${FILE}" != *"/man" ]]; then
                        continue
                    fi
                    ;;
                *)
                    continue
                    ;;
            esac
            ;;
    esac

    echo "Processing ${FILE}"
    mkdir -p "${DEST_DIR}/${FILE_DIR}"
    DEST_FILE_PATH="${DEST_DIR}/${FILE_DIR}/${BASENAME}"
    mv "${FILE}" "${DEST_FILE_PATH}"
done
