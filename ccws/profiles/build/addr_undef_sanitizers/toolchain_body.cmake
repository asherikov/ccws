set(CMAKE_BUILD_TYPE            RelWithDebInfo CACHE STRING "" FORCE)


###############################################################################
# TODO create a debug profile with these settings?
###
# max debug
set(CCWS_DEBUG      "100"           CACHE STRING "" FORCE)
# enable asserts
string(REPLACE      "-DNDEBUG"  ""  CMAKE_CXX_FLAGS_RELWITHDEBINFO "${CMAKE_CXX_FLAGS_RELWITHDEBINFO}")
###############################################################################


set(CCWS_CXX_FLAGS      "${CCWS_CXX_FLAGS} -fsanitize=address -fsanitize=undefined" CACHE STRING "" FORCE)
set(CCWS_LINKER_FLAGS   "${CCWS_CXX_FLAGS} -fsanitize=address -fsanitize=undefined" CACHE STRING "" FORCE)

