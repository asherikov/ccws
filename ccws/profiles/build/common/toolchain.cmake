###############################################################################
# shared cmake checks cache
#
# System check results, compiler introspection results and package search
# results of the packages which have already been built in this build
# profile are harvested into a shared store and replayed into the current
# package before any checks run, which skips the corresponding try_compile
# and search probes. The store is kept in the build directory and is
# invalidated by 'make wsclean' / 'make bp_clean'.
# Set CCWS_CMAKE_CHECKS_CACHE_DISABLE to disable.
###

if(DEFINED ENV{CCWS_BUILD_DIR}
   AND NOT DEFINED ENV{CCWS_CMAKE_CHECKS_CACHE_DISABLE}
   AND EXISTS "${CMAKE_CURRENT_LIST_DIR}/cmake/ccws_cmake_checks_harvest.cmake")
    # the store file name is versioned: stores written by older harvesters
    # replay compiler identification state, which corrupts identification
    # of the packages configured later; the legacy store is discarded and
    # rebuilt from the already built packages
    set(CCWS_CHECKS_STORE "$ENV{CCWS_BUILD_DIR}/.ccws/cmake-checks/initial_cache.cmake")

    # refresh the store from the packages built since the last harvest,
    # sequential colcon builds make their results available in build order
    file(TIMESTAMP "${CCWS_CHECKS_STORE}" _CCWS_STORE_TS "%s" UTC)
    if(NOT _CCWS_STORE_TS)
        set(_CCWS_STORE_TS "0")
    endif()
    file(GLOB _CCWS_CACHES "$ENV{CCWS_BUILD_DIR}/*/CMakeCache.txt")
    foreach(_CCWS_CACHE IN LISTS _CCWS_CACHES)
        get_filename_component(_CCWS_PACKAGE_DIR "${_CCWS_CACHE}" DIRECTORY)
        if("${_CCWS_PACKAGE_DIR}" STREQUAL "${CMAKE_BINARY_DIR}")
            continue()
        endif()
        file(TIMESTAMP "${_CCWS_CACHE}" _CCWS_CACHE_TS "%s" UTC)
        if(_CCWS_CACHE_TS AND _CCWS_STORE_TS LESS "${_CCWS_CACHE_TS}")
            execute_process(
                COMMAND "${CMAKE_COMMAND}"
                    -DHARVEST_BUILD_DIR=$ENV{CCWS_BUILD_DIR}
                    -DHARVEST_STORE=${CCWS_CHECKS_STORE}
                    -DHARVEST_EXCLUDE_DIR=${CMAKE_BINARY_DIR}
                    -P ${CMAKE_CURRENT_LIST_DIR}/cmake/ccws_cmake_checks_harvest.cmake
                RESULT_VARIABLE _CCWS_HARVEST_RESULT
                OUTPUT_VARIABLE _CCWS_HARVEST_OUTPUT
                OUTPUT_STRIP_TRAILING_WHITESPACE
                ERROR_VARIABLE _CCWS_HARVEST_ERROR)
            if(DEFINED ENV{CCWS_CMAKE_CHECKS_CACHE_DEBUG})
                message(STATUS "ccws checks cache: harvested ${_CCWS_CACHE} -> ${CCWS_CHECKS_STORE} (result ${_CCWS_HARVEST_RESULT}) ${_CCWS_HARVEST_OUTPUT} ${_CCWS_HARVEST_ERROR}")
            endif()
            if(NOT _CCWS_HARVEST_RESULT EQUAL 0)
                message(WARNING "ccws: cmake checks cache harvest failed: ${_CCWS_HARVEST_ERROR}")
            endif()
            break()
        endif()
    endforeach()
    unset(_CCWS_STORE_TS)
    unset(_CCWS_CACHE)
    unset(_CCWS_CACHES)
    unset(_CCWS_CACHE_TS)
    unset(_CCWS_PACKAGE_DIR)
    unset(_CCWS_HARVEST_RESULT)
    unset(_CCWS_HARVEST_OUTPUT)
    unset(_CCWS_HARVEST_ERROR)

    # replay shared results into this package
    include("${CCWS_CHECKS_STORE}" OPTIONAL)
endif()

set(CMAKE_VERBOSE_MAKEFILE          ON  CACHE STRING "" FORCE)
set(CMAKE_EXPORT_COMPILE_COMMANDS   ON  CACHE STRING "" FORCE)

# compiler launcher cache tool, selected via CCWS_BUILD_CACHE_TOOL, default ccache
# both ccache and buildcache are forwarders only and do not handle linking
set(CCWS_BUILD_CACHE_TOOL "$ENV{CCWS_BUILD_CACHE_TOOL}")

set(CCWS_BUILD_CACHE_ENABLED TRUE)
if(CCWS_BUILD_CACHE_TOOL STREQUAL "ccache" AND DEFINED ENV{CCACHE_DISABLE})
    set(CCWS_BUILD_CACHE_ENABLED FALSE)
elseif(CCWS_BUILD_CACHE_TOOL STREQUAL "buildcache" AND DEFINED ENV{BUILDCACHE_DISABLE})
    set(CCWS_BUILD_CACHE_ENABLED FALSE)
endif()

if(CCWS_BUILD_CACHE_ENABLED)
    set(CMAKE_C_COMPILER_LAUNCHER   "${CCWS_BUILD_CACHE_TOOL}" CACHE STRING "" FORCE)
    set(CMAKE_CXX_COMPILER_LAUNCHER "${CCWS_BUILD_CACHE_TOOL}" CACHE STRING "" FORCE)
    # ccache additionally supports Fortran, Objective-C, Objective-C++;
    # buildcache only supports C and C++ among languages exposed by cmake.
    if(CCWS_BUILD_CACHE_TOOL STREQUAL "ccache")
        set(CMAKE_Fortran_COMPILER_LAUNCHER  "${CCWS_BUILD_CACHE_TOOL}" CACHE STRING "" FORCE)
        set(CMAKE_OBJC_COMPILER_LAUNCHER     "${CCWS_BUILD_CACHE_TOOL}" CACHE STRING "" FORCE)
        set(CMAKE_OBJCXX_COMPILER_LAUNCHER   "${CCWS_BUILD_CACHE_TOOL}" CACHE STRING "" FORCE)
    endif()
endif()

# TODO deprecated
set(CCWS_BUILD_PROFILE  "$ENV{CCWS_PRIMARY_BUILD_PROFILE}" CACHE STRING "" FORCE)
string(REPLACE "," ";" CCWS_BUILD_PROFILES_LIST "$ENV{CCWS_BUILD_PROFILES}")
set(CCWS_BUILD_PROFILES "${CCWS_BUILD_PROFILES_LIST}" CACHE STRING "" FORCE)

set(CTEST_BUILD_NAME    "${CCWS_BUILD_PROFILES}" CACHE STRING "" FORCE)
# controls testing of CCWS-aware packages
set(CCWS_ENABLE_TESTING ON                     CACHE STRING "" FORCE)
# debug level
set(CCWS_DEBUG          "0"                    CACHE STRING "" FORCE)

# skip some cmake checks, complemented by the shared checks cache, see the
# top of this file
set(CMAKE_C_COMPILER_WORKS      TRUE    CACHE BOOL "" FORCE)
set(CMAKE_CXX_COMPILER_WORKS    TRUE    CACHE BOOL "" FORCE)

# override install prefix provided by colcon: colcon uses host directory
# structure, cmake -- target directory structure, in general they do not match
if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
    set(CMAKE_INSTALL_PREFIX        $ENV{CCWS_INSTALL_DIR_HOST} CACHE STRING "" FORCE)
endif()

if("$ENV{ROS_VERSION}" STREQUAL "1")
    # some packages expect CATKIN_DEVEL_PREFIX to be set when compiling in 'catkin'
    # environment, colcon skips devel phase and does not set it
    # https://github.com/colcon/colcon-ros/issues/119
    set(CATKIN_DEVEL_PREFIX         "${CMAKE_BINARY_DIR}/devel" CACHE STRING "" FORCE)
endif()

# ccws cmake utilities
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/cmake/")
# assuming packages install modules here
list(APPEND CMAKE_MODULE_PATH "${CMAKE_INSTALL_PREFIX}/share/cmake/Modules/")


###############################################################################
# compilation flags
###
set(CMAKE_POSITION_INDEPENDENT_CODE ON)
# -ffile-prefix-map: rewrite absolute paths to avoid leaks and reproduce builds, use `set substitute-path` in gdb if needed
set(CCWS_COMMON_FLAGS "-fdiagnostics-color -ffile-prefix-map='$ENV{CCWS_SOURCE_DIR}/=/'")
string(FIND "${CMAKE_CXX_FLAGS}" "${CCWS_COMMON_FLAGS}" FIND_RESULT)
if(${FIND_RESULT} EQUAL -1) # prevent command line growth on rebuild
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${CCWS_COMMON_FLAGS}" CACHE STRING "" FORCE)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${CCWS_COMMON_FLAGS}" CACHE STRING "" FORCE)
endif ()
set(CMAKE_CXX_STANDARD "$ENV{CCWS_CXX_STANDARD}")
set(CCWS_CXX_FLAGS_COMMON "-std=c++$ENV{CCWS_CXX_STANDARD} -fstack-protector-strong" CACHE STRING "" FORCE)
set(CCWS_CXX_FLAGS_WARNINGS "-Wall -Wextra -Wshadow -Werror -Werror=return-type -Werror=pedantic -pedantic-errors -Wno-deprecated-declarations" CACHE STRING "" FORCE)
set(CCWS_CXX_FLAGS "${CCWS_CXX_FLAGS_COMMON} ${CCWS_CXX_FLAGS_WARNINGS}" CACHE STRING "" FORCE)

# -flto
# performance gain seems to be marginal in general, but the main limiting
# factor currently (gcc7) is:
# "Link-time optimization does not work well with generation of debugging
# information. Combining -flto with -g is currently experimental and
# expected to produce unexpected results."

# https://stackoverflow.com/questions/67802356/how-to-make-cmake-pass-d-argument-to-ar-for-reproducible-build-of-a-static-libra
# deterministic flag seems to be enabled by default now
#set(CMAKE_CXX_ARCHIVE_CREATE "<CMAKE_AR> qcD <TARGET> <LINK_FLAGS> <OBJECTS>")
#set(CMAKE_CXX_ARCHIVE_FINISH "<CMAKE_RANLIB> -D <TARGET>")

###############################################################################
# cmake debug
###

#set(CMAKE_FIND_DEBUG_MODE ON)

# Find*.cmake debug output
#set(Boost_DEBUG ON CACHE STRING "" FORCE)
#set(Protobuf_DEBUG ON CACHE STRING "" FORCE)


###############################################################################
# workspace specific cmake parameters
###

include("$ENV{CCWS_SOURCE_EXTRAS}/toolchain.cmake" OPTIONAL RESULT_VARIABLE CCWS_SOURCE_EXTRAS_TOOLCHAIN)
#message("Extra toolchain inclusion: ${CCWS_SOURCE_EXTRAS_TOOLCHAIN}")

