#!/usr/bin/env bash

set -Ee
set -o pipefail

# Split files that belong to a binary subpackage out of a staged debian
# package root into a separate staging directory, which is used to generate
# '-dev' / '-doc' / '-dbg' binary packages:
#
#   dev -- development files: 'include' and 'cmake' directories, static
#           libraries, pkg-config files, loose header files; note that shared
#           libraries in ROS workspaces are typically unversioned real files
#           (not symlinks) and must stay in the runtime package
#   doc -- documentation files: 'doc' and 'man' directories, markdown files
#   dbg -- debug symbols: extracted from binaries and libraries, which are
#           stripped in the process; symbols are placed into the mirrored
#           '/usr/lib/debug' layout that gdb searches by default, see
#           https://sourceware.org/gdb/current/onlinedocs/gdb.html/Separate-Debug-Files.html
#
# Everything else (shared libraries, executables, message definitions, launch
# files, ament index, colcon setup scripts) remains in the original directory
# and is packed into the main package.
#
# This script supersedes ccws_move_dev_files.sh and
# ccws_extract_debug_info.sh.

if [ $# -lt 3 ] || [ $# -gt 4 ]
then
    echo "Usage: $0 <dev|doc|dbg> <install_root> <subpackage_root> [arch_triplet]" >&2
    echo "  dev|doc|dbg: subpackage type, selects the file set to split off" >&2
    echo "  install_root: staged debian package root to process" >&2
    echo "  subpackage_root: destination directory for the split off files" >&2
    echo "  arch_triplet: optional target architecture triplet (e.g.," >&2
    echo "    x86_64-linux-gnu) used to prefix binutils tools, 'dbg' only" >&2
    exit 1
fi

SUBPACKAGE="${1}"
INSTALL_ROOT="$(realpath "$2")"
DEST_ROOT="$(realpath -m "$3")"
# the triplet is used to prefix binutils tools, 'dbg' only
ARCH_TRIPLET="${4:-}"

if [ ! -d "${INSTALL_ROOT}" ]; then
    echo "Error: Directory '${INSTALL_ROOT}' does not exist" >&2
    exit 1
fi

rm -rf "${DEST_ROOT}"


# extract debug information from a file into the mirrored gdb layout
extract_debug_info() {
    local FILE_PATH="${1}"
    local OBJCOPY_PREFIX="${2:-}"

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
    local RELATIVE_PATH
    local TARGET_DIR
    RELATIVE_PATH="$(realpath --relative-to="${INSTALL_ROOT}" "${FILE_PATH}")"
    TARGET_DIR="${DEBUG_FILES_ROOT}/$(dirname "${RELATIVE_PATH}")"
    mkdir -p "${TARGET_DIR}"
    mv "${FILE}.debug" "${TARGET_DIR}/"
    # debian debug packages are expected to use standard file permissions
    chmod 644 "${TARGET_DIR}/${FILE}.debug"
    popd > /dev/null
}


case "${SUBPACKAGE}" in
    dev|doc)
        if [ "${SUBPACKAGE}" = dev ]
        then
            # 'include' and 'cmake' directories are moved as a whole, together
            # with static libraries, pkg-config files, and loose header files
            FIND_ARGS=(
                \( -type d \( -name 'include' -o -name 'cmake' \) -prune -print0 \)
                -o
                \( -type f \( -name '*.a' -o -name '*.pc'
                    -o -name '*.h' -o -name '*.hpp' -o -name '*.hxx'
                    -o -name '*.hh' -o -name '*.H' -o -name '*.tpp' \) -print0 \)
            )
        else
            # 'doc' and 'man' directories are moved as a whole, together with
            # markdown files
            FIND_ARGS=(
                \( -type d \( -name 'doc' -o -name 'man' \) -prune -print0 \)
                -o
                \( -type f \( -name '*.md' -o -name '*.markdown' \) -print0 \)
            )
        fi

        mkdir -p "${DEST_ROOT}"

        FILE_LIST="$(mktemp)"
        trap 'rm -f "${FILE_LIST}"' EXIT

        pushd "${INSTALL_ROOT}" > /dev/null

        find . "${FIND_ARGS[@]}" > "${FILE_LIST}"

        if [ -s "${FILE_LIST}" ]
        then
            echo "Moving $(tr -cd '\0' < "${FILE_LIST}" | wc -c) ${SUBPACKAGE} entries to ${DEST_ROOT}"
            tar --null --files-from="${FILE_LIST}" -cf - \
                | tar -C "${DEST_ROOT}" -xf -
            xargs -0 --no-run-if-empty rm -rf -- < "${FILE_LIST}"
        fi

        popd > /dev/null
        ;;
    dbg)
        DEBUG_FILES_ROOT="${DEST_ROOT}/usr/lib/debug"
        mkdir -p "${DEBUG_FILES_ROOT}"

        OBJCOPY_PREFIX=""
        if [ -n "${ARCH_TRIPLET}" ]; then
            OBJCOPY_PREFIX="${ARCH_TRIPLET}-"
        fi

        # Process object and shared library files
        find "${INSTALL_ROOT}" -not -path "*/.git/*" -type f \( -name "*.o" -o -name "*.so" -o -name "*.so.*" \) -print0 | while IFS= read -r -d '' OBJ_FILE; do
            extract_debug_info "${OBJ_FILE}" "${OBJCOPY_PREFIX}"
        done

        # Process executable files; 'awk' is used instead of 'grep' since
        # the latter fails when there is nothing to match, which aborts the
        # whole pipeline due to 'pipefail'
        find "${INSTALL_ROOT}" -not -path "*/.git/*" -type f -executable -exec file {} \; 2>/dev/null | \
        awk '/:.*(executable|shared object)/ && !(/: data/)' | \
        cut -d: -f1 | \
        sort -u | \
        while read -r EXE_FILE; do
            # Skip .o and .so files as they were already processed
            if [[ "${EXE_FILE}" =~ \.(o|so)$ ]]; then
                continue
            fi

            extract_debug_info "${EXE_FILE}" "${OBJCOPY_PREFIX}"
        done
        ;;
    *)
        echo "Error: unknown subpackage type '${SUBPACKAGE}', expected 'dev', 'doc' or 'dbg'" >&2
        exit 1
        ;;
esac
