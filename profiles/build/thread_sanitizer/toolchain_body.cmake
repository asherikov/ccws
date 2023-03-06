set(CMAKE_BUILD_TYPE            RelWithDebInfo CACHE STRING "" FORCE)

set(CCWS_CXX_FLAGS       "${CCWS_CXX_FLAGS} -fsanitize=thread" CACHE STRING "" FORCE)
set(CCWS_LINKER_FLAGS    "${CCWS_CXX_FLAGS} -fsanitize=thread" CACHE STRING "" FORCE)
