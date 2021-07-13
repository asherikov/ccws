include("${CMAKE_CURRENT_LIST_DIR}/../common/cmake_flags.cmake")
set(CMAKE_BUILD_TYPE            RelWithDebInfo CACHE STRING "" FORCE)

include("${CMAKE_CURRENT_LIST_DIR}/../common/cxx_flags.cmake")
set(CCW_CXX_FLAGS       "${CCW_CXX_FLAGS} -fsanitize=address -fsanitize=undefined" CACHE STRING "" FORCE)
set(CCW_LINKER_FLAGS    "${CCW_CXX_FLAGS} -fsanitize=address -fsanitize=undefined" CACHE STRING "" FORCE)

