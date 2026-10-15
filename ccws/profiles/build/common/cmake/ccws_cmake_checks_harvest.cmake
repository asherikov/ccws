# CCWS shared cmake checks cache harvester.
#
# Collects results which are safe to reuse between cmake packages built with
# the same build profile:
#   - system check results (check_*, try_compile), identified by the
#     docstrings which the stock cmake Check* modules stamp them with
#   - compiler introspection results, taken as a coherent set from the
#     CMakeFiles/<version>/CMake*Compiler.cmake + CMakeSystem.cmake of the
#     most recently built package
#   - package search results (<pkg>_DIR, *_INCLUDE_DIR, *_LIBRARY*,
#     *_EXECUTABLE) restricted to configured allowed path prefixes
#
# Entries which have different values in different packages are treated as
# package specific and dropped. The accumulated state is stored as a cmake
# script of plain cache 'set()' commands which the toolchain file includes
# before any checks run, see profiles/build/common/toolchain.cmake.
#
# The store is kept inside the profile build directory and is invalidated by
# 'make wsclean' / 'make bp_clean'.
#
# Usage (script mode):
#   cmake -DHARVEST_BUILD_DIR=<build base> \
#         -DHARVEST_STORE=<store file> \
#         [-DHARVEST_EXCLUDE_DIR=<currently configured package build dir>] \
#         -P ccws_cmake_checks_harvest.cmake

# NEW policies are required for correct list() handling of empty elements,
# this affects only this script and not the projects being harvested
cmake_minimum_required(VERSION 3.10)

if(NOT DEFINED HARVEST_BUILD_DIR OR NOT DEFINED HARVEST_STORE)
    message(FATAL_ERROR "HARVEST_BUILD_DIR and HARVEST_STORE must be defined")
endif()
if(NOT DEFINED HARVEST_EXCLUDE_DIR)
    set(HARVEST_EXCLUDE_DIR "")
endif()


###############################################################################
# helpers
###

function(_ccws_escape out_var value)
    set(_escaped "${value}")
    string(REPLACE "\\" "\\\\" _escaped "${_escaped}")
    string(REPLACE "\"" "\\\"" _escaped "${_escaped}")
    string(REPLACE "\n" "\\n" _escaped "${_escaped}")
    string(REPLACE "\r" "\\r" _escaped "${_escaped}")
    string(REPLACE "\t" "\\t" _escaped "${_escaped}")
    set(${out_var} "${_escaped}" PARENT_SCOPE)
endfunction()

function(_ccws_unescape out_var value)
    set(_unescaped "${value}")
    string(REPLACE "\\n" "\n" _unescaped "${_unescaped}")
    string(REPLACE "\\r" "\r" _unescaped "${_unescaped}")
    string(REPLACE "\\t" "\t" _unescaped "${_unescaped}")
    string(REPLACE "\\\"" "\"" _unescaped "${_unescaped}")
    string(REPLACE "\\\\" "\\" _unescaped "${_unescaped}")
    set(${out_var} "${_unescaped}" PARENT_SCOPE)
endfunction()

# remember an entry, tracking cross package conflicts:
# equal value reconfirmes the entry, different value marks it as conflicting
# and the entry is excluded from the store.
# entry data is kept in per name variables: values may contain semicolons
# which cannot be stored in parallel lists
function(_ccws_remember name value type doc)
    if("${value}" STREQUAL "")
        return()
    endif()
    if("${value}" MATCHES "${HARVEST_BUILD_DIR}")
        # paths into the build directory are package specific
        return()
    endif()
    list(FIND _names "${name}" _found_index)
    if(NOT _found_index EQUAL -1)
        set(_known_value "${_entry_value_${name}}")
        if(NOT "${_known_value}" STREQUAL "${value}")
            list(FIND _conflicts "${name}" _conflict_index)
            if(_conflict_index EQUAL -1)
                list(APPEND _conflicts "${name}")
                set(_conflicts "${_conflicts}" PARENT_SCOPE)
            endif()
        endif()
        return()
    endif()
    list(APPEND _names "${name}")
    set(_names "${_names}" PARENT_SCOPE)
    set("_entry_value_${name}" "${value}" PARENT_SCOPE)
    set("_entry_type_${name}" "${type}" PARENT_SCOPE)
    set("_entry_doc_${name}" "${doc}" PARENT_SCOPE)
endfunction()


###############################################################################
# accumulated state
###

set(_names "")
set(_conflicts "")

# allowed absolute path prefixes for shared search results
set(_allowed_prefixes "")
if(DEFINED ENV{CCWS_INSTALL_DIR_HOST} AND NOT "$ENV{CCWS_INSTALL_DIR_HOST}" STREQUAL "")
    list(APPEND _allowed_prefixes "$ENV{CCWS_INSTALL_DIR_HOST}")
endif()
if(DEFINED ENV{ROS_DISTRO} AND NOT "$ENV{ROS_DISTRO}" STREQUAL "")
    list(APPEND _allowed_prefixes "/opt/ros/$ENV{ROS_DISTRO}")
endif()
if(DEFINED ENV{CCWS_SYSROOT_MOUNTPOINT} AND NOT "$ENV{CCWS_SYSROOT_MOUNTPOINT}" STREQUAL "")
    list(APPEND _allowed_prefixes "$ENV{CCWS_SYSROOT_MOUNTPOINT}")
else()
    # native builds: system locations are identical for all packages
    list(APPEND _allowed_prefixes "/usr/" "/lib/" "/lib64/" "/bin/" "/sbin/" "/etc/")
endif()
# enforce directory prefix semantics
set(_normalized_prefixes "")
foreach(_prefix IN LISTS _allowed_prefixes)
    if(NOT "${_prefix}" MATCHES "/$")
        string(APPEND _prefix "/")
    endif()
    list(APPEND _normalized_prefixes "${_prefix}")
endforeach()
set(_allowed_prefixes "${_normalized_prefixes}")

# names which must never be shared
set(_name_blacklist_regex "\
^(CMAKE_HOME_DIRECTORY|\
CMAKE_CACHEFILE_DIR|\
CMAKE_BUILD_TYPE|\
CMAKE_INSTALL_PREFIX|\
CMAKE_GENERATOR[^_]*|\
CMAKE_EXTRA_GENERATOR|\
CATKIN_DEVEL_PREFIX|\
CCWS_[A-Za-z0-9_]*\
)$")

# docstrings stamped by the stock cmake Check* modules
set(_check_doc_regex "^Have |^Result of TRY_COMPILE|^Test |^CHECK_TYPE_SIZE")

# variable name suffixes of find_* results, see cmake Find modules
set(_find_name_regex "\
(_DIR|_INCLUDE_DIR|_INCLUDE_DIRS|_EXECUTABLE|_LIBRARY_DIR|\
_LIBRARY(_DEBUG|_RELEASE|_MINSIZEREL|_RELWITHDEBINFO)?)$")

# compiler introspection *data* which is safe to share between packages.
# Identification state and results (CMAKE_<LANG>_COMPILER_ID,
# _COMPILER_ID_RUN, _PLATFORM_ID, _SIMULATE_*, CMAKE_SYSTEM*, ...) are
# deliberately excluded: presetting them in the cache corrupts compiler
# identification of the packages configured later, e.g. an empty
# CMAKE_<LANG>_PLATFORM_ID switches installs to the pre-install relink
# flow, which is not performed by 'cmake --install' used by colcon, while
# a preset CMAKE_SYSTEM_NAME makes cmake treat native builds as cross
# compilation
set(_introspection_name_regex "\
^(CMAKE_(AR|RANLIB|LINKER)|\
CMAKE_(C|CXX)_(COMPILER|COMPILER_AR|COMPILER_RANLIB|COMPILER_VERSION|\
COMPILER_WORKS|ABI_COMPILED|\
IMPLICIT_INCLUDE_DIRECTORIES|IMPLICIT_LINK_LIBRARIES|\
IMPLICIT_LINK_DIRECTORIES|IMPLICIT_LINK_FRAMEWORK_DIRECTORIES|\
STANDARD_COMPUTED_DEFAULT|EXTENSIONS_COMPUTED_DEFAULT|\
COMPILE_FEATURES|[0-9]+_COMPILE_FEATURES|\
SIZEOF_DATA_PTR|COMPILER_ABI|BYTE_ORDER|LIBRARY_ARCHITECTURE))$")


###############################################################################
# reload previous state from the store
###

if(EXISTS "${HARVEST_STORE}")
    file(STRINGS "${HARVEST_STORE}" _store_lines)
    foreach(_line IN LISTS _store_lines)
        if(_line MATCHES "^#conflict ([A-Za-z0-9_]+)$")
            list(APPEND _conflicts "${CMAKE_MATCH_1}")
        elseif(_line MATCHES "^set\\(([A-Za-z0-9_]+) \"(.*)\" CACHE (INTERNAL|BOOL|STRING|PATH|FILEPATH) \"(.*)\"\\)$")
            _ccws_unescape(_value "${CMAKE_MATCH_2}")
            _ccws_unescape(_doc "${CMAKE_MATCH_4}")
            _ccws_remember("${CMAKE_MATCH_1}" "${_value}" "${CMAKE_MATCH_3}" "${_doc}")
        endif()
    endforeach()
endif()


###############################################################################
# candidate caches: newer than the store, excluding the configured package
###

file(TIMESTAMP "${HARVEST_STORE}" _store_ts "%s" UTC)
if(NOT _store_ts)
    set(_store_ts "0")
endif()

file(GLOB _cache_files "${HARVEST_BUILD_DIR}/*/CMakeCache.txt")
set(_candidates "")
foreach(_cache_file IN LISTS _cache_files)
    get_filename_component(_package_dir "${_cache_file}" DIRECTORY)
    if("${_package_dir}" STREQUAL "${HARVEST_EXCLUDE_DIR}")
        continue()
    endif()
    file(TIMESTAMP "${_cache_file}" _cache_ts "%s" UTC)
    if(_cache_ts AND _store_ts LESS "${_cache_ts}")
        list(APPEND _candidates "${_cache_file}")
    endif()
endforeach()

if(NOT _candidates)
    if(DEFINED ENV{CCWS_CMAKE_CHECKS_CACHE_DEBUG})
        message(STATUS "ccws checks cache harvester: no new caches to harvest, store: ${HARVEST_STORE}")
    endif()
    return()
endif()
if(DEFINED ENV{CCWS_CMAKE_CHECKS_CACHE_DEBUG})
    message(STATUS "ccws checks cache harvester: candidates: ${_candidates}")
endif()


###############################################################################
# harvest entries from candidate caches
###

foreach(_cache_file IN LISTS _candidates)
    get_filename_component(_package_dir "${_cache_file}" DIRECTORY)

    # first pass: identify entries, values are fetched with load_cache which
    # handles escaping and multi line values correctly
    set(_wanted_names "")
    set(_wanted_types "")
    set(_wanted_docs "")
    set(_doc "")
    file(STRINGS "${_cache_file}" _cache_lines)
    foreach(_line IN LISTS _cache_lines)
        if(_line MATCHES "^//(.*)$")
            if(NOT "${_doc}" STREQUAL "")
                string(APPEND _doc " ")
            endif()
            string(APPEND _doc "${CMAKE_MATCH_1}")
        elseif(_line MATCHES "^([A-Za-z0-9_]+):(INTERNAL|BOOL|STRING|PATH|FILEPATH|STATIC)=")
            set(_name "${CMAKE_MATCH_1}")
            set(_type "${CMAKE_MATCH_2}")
            set(_want FALSE)
            if(NOT _name MATCHES "${_name_blacklist_regex}")
                if(_type STREQUAL "INTERNAL" AND _doc MATCHES "${_check_doc_regex}")
                    set(_want TRUE)
                elseif((_type STREQUAL "PATH" OR _type STREQUAL "FILEPATH" OR
                        (_type STREQUAL "STRING" AND _name MATCHES "_DIR$"))
                       AND _name MATCHES "${_find_name_regex}"
                       AND NOT _name MATCHES "^CMAKE_")
                    set(_want TRUE)
                endif()
            endif()
            if(_want)
                list(APPEND _wanted_names "${_name}")
                list(APPEND _wanted_types "${_type}")
                list(APPEND _wanted_docs "${_doc}")
            endif()
            set(_doc "")
        else()
            set(_doc "")
        endif()
    endforeach()

    if(NOT _wanted_names)
        continue()
    endif()

    # second pass: fetch and filter values
    load_cache("${_package_dir}" READ_WITH_PREFIX _HARVEST_VALUE_ ${_wanted_names})
    list(LENGTH _wanted_names _wanted_count)
    math(EXPR _last_index "${_wanted_count} - 1")
    foreach(_index RANGE ${_last_index})
        list(GET _wanted_names ${_index} _name)
        list(GET _wanted_types ${_index} _type)
        list(GET _wanted_docs ${_index} _doc)
        set(_value "${_HARVEST_VALUE_${_name}}")
        if("${_value}" STREQUAL "")
            continue()
        endif()
        if("${_value}" MATCHES "${HARVEST_BUILD_DIR}")
            continue()
        endif()
        if(NOT _type STREQUAL "INTERNAL")
            # search results must point into shared locations
            set(_prefix_ok FALSE)
            foreach(_prefix IN LISTS _allowed_prefixes)
                string(FIND "${_value}" "${_prefix}" _prefix_pos)
                if(_prefix_pos EQUAL 0)
                    set(_prefix_ok TRUE)
                    break()
                endif()
            endforeach()
            if(NOT _prefix_ok)
                continue()
            endif()
        endif()
        _ccws_remember("${_name}" "${_value}" "${_type}" "${_doc}")
    endforeach()
endforeach()


###############################################################################
# harvest compiler introspection from the most recent candidate
#
# introspection results live in CMakeFiles/<version>/*.cmake files, not in
# the cache; they are taken as a whole from a single package to stay
# consistent. State flags which control cmake loading logic are excluded.
###

set(_newest_info_dir "")
set(_newest_info_ts "0")
foreach(_cache_file IN LISTS _candidates)
    get_filename_component(_info_dir "${_cache_file}" DIRECTORY)
    set(_info_dir "${_info_dir}/CMakeFiles/${CMAKE_VERSION}")
    if(NOT "${HARVEST_EXCLUDE_DIR}" STREQUAL ""
       AND "${_info_dir}" MATCHES "^${HARVEST_EXCLUDE_DIR}/")
        continue()
    endif()
    file(TIMESTAMP "${_info_dir}/CMakeCXXCompiler.cmake" _info_ts "%s" UTC)
    if(_info_ts AND _newest_info_ts LESS "${_info_ts}")
        set(_newest_info_ts "${_info_ts}")
        set(_newest_info_dir "${_info_dir}")
    endif()
endforeach()

if(NOT "${_newest_info_dir}" STREQUAL "")
    file(GLOB _info_files "${_newest_info_dir}/*Compiler.cmake" "${_newest_info_dir}/CMakeSystem.cmake")
    foreach(_info_file IN LISTS _info_files)
        file(STRINGS "${_info_file}" _info_lines)
        foreach(_line IN LISTS _info_lines)
            set(_name "")
            set(_value "")
            if(_line MATCHES "^set\\(([A-Za-z0-9_]+) \"(.*)\"\\)$")
                set(_name "${CMAKE_MATCH_1}")
                set(_value "${CMAKE_MATCH_2}")
            elseif(_line MATCHES "^set\\(([A-Za-z0-9_]+) ([^\"].*)\\)$")
                set(_name "${CMAKE_MATCH_1}")
                set(_value "${CMAKE_MATCH_2}")
            endif()
            if("${_name}" STREQUAL "" OR "${_value}" STREQUAL "")
                continue()
            endif()
            # share only identification-independent data, see
            # _introspection_name_regex
            if(NOT _name MATCHES "${_introspection_name_regex}")
                continue()
            endif()
            _ccws_remember("${_name}" "${_value}" "INTERNAL" "")
        endforeach()
    endforeach()
endif()


###############################################################################
# write the store atomically
###

# check_type_size() stores its results in pairs: SIZEOF_<X> holds the size,
# HAVE_SIZEOF_<X> marks the underlying try_compile as done. Dropping only the
# conflicting size entry would leave the stale marker behind and silently
# skip the check in the packages configured later
set(_conflicts_work "${_conflicts}")
foreach(_name IN LISTS _conflicts_work)
    if(_name MATCHES "^SIZEOF_(.+)$")
        set(_paired_name "HAVE_SIZEOF_${CMAKE_MATCH_1}")
        list(FIND _names "${_paired_name}" _paired_index)
        if(NOT _paired_index EQUAL -1)
            list(APPEND _conflicts "${_paired_name}")
        endif()
    endif()
endforeach()

set(_content "# generated by the ccws cmake checks cache harvester, do not edit\n")
foreach(_name IN LISTS _conflicts)
    string(APPEND _content "#conflict ${_name}\n")
endforeach()
foreach(_name IN LISTS _names)
    list(FIND _conflicts "${_name}" _conflict_index)
    if(NOT _conflict_index EQUAL -1)
        continue()
    endif()
    set(_value "${_entry_value_${_name}}")
    set(_type "${_entry_type_${_name}}")
    set(_doc "${_entry_doc_${_name}}")
    _ccws_escape(_escaped_value "${_value}")
    _ccws_escape(_escaped_doc "${_doc}")
    string(APPEND _content "set(${_name} \"${_escaped_value}\" CACHE ${_type} \"${_escaped_doc}\")\n")
endforeach()

get_filename_component(_store_dir "${HARVEST_STORE}" DIRECTORY)
file(MAKE_DIRECTORY "${_store_dir}")
string(RANDOM LENGTH 8 _random)
set(_tmp_store "${HARVEST_STORE}.tmp${_random}")
file(WRITE "${_tmp_store}" "${_content}")
file(RENAME "${_tmp_store}" "${HARVEST_STORE}")

if(DEFINED ENV{CCWS_CMAKE_CHECKS_CACHE_DEBUG})
    list(LENGTH _names _entry_count)
    list(LENGTH _conflicts _conflict_count)
    message(STATUS "ccws checks cache: ${_entry_count} entries, ${_conflict_count} conflicts, store: ${HARVEST_STORE}")
endif()
