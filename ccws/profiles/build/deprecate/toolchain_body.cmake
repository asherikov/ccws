# warnings about deprecated declarations are disabled by default
# (see common/toolchain.cmake), re-enable them
string(REPLACE "-Wno-deprecated-declarations" "-Wdeprecated-declarations" CCWS_CXX_FLAGS_WARNINGS "${CCWS_CXX_FLAGS_WARNINGS}")
set(CCWS_CXX_FLAGS_WARNINGS "${CCWS_CXX_FLAGS_WARNINGS}" CACHE STRING "" FORCE)
string(REPLACE "-Wno-deprecated-declarations" "-Wdeprecated-declarations" CCWS_CXX_FLAGS "${CCWS_CXX_FLAGS}")
set(CCWS_CXX_FLAGS "${CCWS_CXX_FLAGS}" CACHE STRING "" FORCE)
