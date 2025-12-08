set(CMAKE_VERBOSE_MAKEFILE          ON  CACHE STRING "" FORCE)
set(CMAKE_EXPORT_COMPILE_COMMANDS   ON  CACHE STRING "" FORCE)

# ccache does not work for linking
if(NOT DEFINED ENV{CCACHE_DISABLE})
    set(CMAKE_C_COMPILER_LAUNCHER   ccache  CACHE STRING "" FORCE)
    set(CMAKE_CXX_COMPILER_LAUNCHER ccache  CACHE STRING "" FORCE)
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

# skip some cmake checks
# TODO https://github.com/cristianadam/cmake-checks-cache
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
set(CCWS_CXX_FLAGS_COMMON "-std=c++$ENV{CCWS_CXX_STANDARD} -fstack-protector-strong" CACHE STRING "" FORCE)
set(CCWS_CXX_FLAGS_WARNINGS "-Wall -Wextra -Wshadow -Werror -Werror=return-type -Werror=pedantic -pedantic-errors" CACHE STRING "" FORCE)
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

