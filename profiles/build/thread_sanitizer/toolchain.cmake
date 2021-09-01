include("${CMAKE_CURRENT_LIST_DIR}/../common/toolchain.cmake")
set(CMAKE_BUILD_TYPE            RelWithDebInfo CACHE STRING "" FORCE)

set(CCWS_CXX_FLAGS       "${CCWS_CXX_FLAGS} -fsanitize=thread" CACHE STRING "" FORCE)
set(CCWS_LINKER_FLAGS    "${CCWS_CXX_FLAGS} -fsanitize=thread" CACHE STRING "" FORCE)

include("${CMAKE_CURRENT_LIST_DIR}/../vendor/toolchain_suffix.cmake" OPTIONAL)
