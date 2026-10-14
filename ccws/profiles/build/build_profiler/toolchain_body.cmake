# this profile is compiler dependent and cannot be used as a mixin:
# ClangBuildAnalyzer relies on '-ftime-trace', which is a Clang feature, so
# the compiler has to be forced
set(CMAKE_BUILD_TYPE    RelWithDebInfo CACHE STRING "" FORCE)
set(CMAKE_CXX_COMPILER  clang++-$ENV{CCWS_LLVM_VERSION} CACHE STRING "" FORCE)
set(CMAKE_C_COMPILER    clang-$ENV{CCWS_LLVM_VERSION}   CACHE STRING "" FORCE)


# ClangBuildAnalyzer consumes '-ftime-trace' output:
#   https://github.com/aras-p/ClangBuildAnalyzer
# one JSON timeline file is generated next to every object file
set(CCWS_BUILD_PROFILER_FLAGS "-ftime-trace")
string(FIND "${CMAKE_C_FLAGS}" "${CCWS_BUILD_PROFILER_FLAGS}" CCWS_BUILD_PROFILER_FIND_C)
if(${CCWS_BUILD_PROFILER_FIND_C} EQUAL -1) # prevent command line growth on rebuild
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${CCWS_BUILD_PROFILER_FLAGS}" CACHE STRING "" FORCE)
endif()
string(FIND "${CMAKE_CXX_FLAGS}" "${CCWS_BUILD_PROFILER_FLAGS}" CCWS_BUILD_PROFILER_FIND_CXX)
if(${CCWS_BUILD_PROFILER_FIND_CXX} EQUAL -1)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${CCWS_BUILD_PROFILER_FLAGS}" CACHE STRING "" FORCE)
endif()


# compilation caches must not be used: cached compilations are not executed
# and distort the measurements; 'ccache' and 'buildcache' are disabled via
# the environment in 'setup.bash', and any compiler launcher configured
# before this point, e.g. by workspace extras, is overridden
set(CMAKE_C_COMPILER_LAUNCHER   "" CACHE STRING "" FORCE)
set(CMAKE_CXX_COMPILER_LAUNCHER "" CACHE STRING "" FORCE)
