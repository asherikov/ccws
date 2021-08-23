include("${CMAKE_CURRENT_LIST_DIR}/../common/toolchain_header.cmake")
set(CMAKE_BUILD_TYPE            RelWithDebInfo CACHE STRING "" FORCE)

include("${CMAKE_CURRENT_LIST_DIR}/../common/cxx_flags.cmake")
set(CCWS_CXX_FLAGS      "${CCWS_CXX_FLAGS} -fsanitize=address -fsanitize=undefined" CACHE STRING "" FORCE)
set(CCWS_LINKER_FLAGS   "${CCWS_CXX_FLAGS} -fsanitize=address -fsanitize=undefined" CACHE STRING "" FORCE)

include("${CMAKE_CURRENT_LIST_DIR}/../common/toolchain_footer.cmake")
