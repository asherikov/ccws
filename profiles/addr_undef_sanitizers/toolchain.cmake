set(CMAKE_VERBOSE_MAKEFILE      ON      CACHE STRING "" FORCE)
set(CMAKE_BUILD_TYPE            RelWithDebInfo CACHE STRING "" FORCE)
set(CMAKE_CXX_COMPILER_LAUNCHER ccache  CACHE STRING "" FORCE)

set(CCW_BUILD_PROFILE   "addr_undef_sanitizers" CACHE STRING "" FORCE)

include("${CMAKE_CURRENT_LIST_DIR}/../common/cxx_flags.cmake")
set(CCW_CXX_FLAGS       "${CCW_CXX_FLAGS} -fsanitize=address -fsanitize=undefined" CACHE STRING "" FORCE)
set(CCW_LINKER_FLAGS    "${CCW_CXX_FLAGS} -fsanitize=address -fsanitize=undefined" CACHE STRING "" FORCE)

