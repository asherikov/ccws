# build type is inherited from the base profile; optimization degrades line
# attribution in coverage reports (inlining), which is usually acceptable,
# a debug base profile can be used when precise line coverage is required

# `--coverage` equals `-fprofile-arcs -ftest-coverage` for compilation and
# `-lgcov` for linking; picked up only by ccws aware packages in
# ccws_set_cmake_flags.cmake, packages that do not include ccws cmake
# modules are not instrumented and are missing from reports
#
# the base toolchain crops workspace paths with `-ffile-prefix-map`, which
# prevents `gcov` from locating sources via paths recorded in `.gcno` files;
# the identity mapping appended here overrides it, since gcc applies the
# last matching `-ffile-prefix-map` entry and ccws flags go after
# `CMAKE_CXX_FLAGS` in `ccws_set_cmake_flags.cmake`; non-instrumented
# packages keep path cropping
set(CCWS_CXX_FLAGS    "${CCWS_CXX_FLAGS} --coverage -ffile-prefix-map='$ENV{CCWS_SOURCE_DIR}/=$ENV{CCWS_SOURCE_DIR}/'" CACHE STRING "" FORCE)
set(CCWS_LINKER_FLAGS "${CCWS_CXX_FLAGS}" CACHE STRING "" FORCE)
