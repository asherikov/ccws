set(CMAKE_VERBOSE_MAKEFILE      ON      CACHE STRING "" FORCE)

set(CMAKE_C_COMPILER_LAUNCHER   ccache  CACHE STRING "" FORCE)
set(CMAKE_CXX_COMPILER_LAUNCHER ccache  CACHE STRING "" FORCE)

set(CCWS_BUILD_PROFILE   "$ENV{CCWS_PROFILE}"     CACHE STRING "" FORCE)

# skip some cmake checks
# TODO https://github.com/cristianadam/cmake-checks-cache
set(CMAKE_C_COMPILER_WORKS      TRUE    CACHE BOOL "" FORCE)
set(CMAKE_CXX_COMPILER_WORKS    TRUE    CACHE BOOL "" FORCE)


###############################################################################
# cmake debug
###

#set(CMAKE_FIND_DEBUG_MODE ON)
