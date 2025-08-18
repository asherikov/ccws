set(CMAKE_BUILD_TYPE            RelWithDebInfo CACHE STRING "" FORCE)
# disable optimization to increase compilation speed
set(CMAKE_CXX_FLAGS_RELWITHDEBINFO "-O0" CACHE STRING "" FORCE)
set(CMAKE_C_FLAGS_RELWITHDEBINFO "-O0" CACHE STRING "" FORCE)

set(CMAKE_CXX_COMPILER /usr/share/clang/scan-build-$ENV{CCWS_LLVM_VERSION}/libexec/c++-analyzer  CACHE STRING "" FORCE)
set(CMAKE_C_COMPILER /usr/share/clang/scan-build-$ENV{CCWS_LLVM_VERSION}/libexec/ccc-analyzer  CACHE STRING "" FORCE)


find_program(CCWS_CLANG_TIDY_EXECUTABLE NAMES clang-tidy-$ENV{CCWS_LLVM_VERSION} REQUIRED)

set(CCWS_CLANG_TIDY "${CCWS_CLANG_TIDY_EXECUTABLE};--config-file=$ENV{BUILD_PROFILES_DIR}/clang_tidy/clang_tidy_config.yaml;--header-filter=$ENV{WORKSPACE_SRC}/.*")

set(CCWS_CLANG_TIDY "${CCWS_CLANG_TIDY}" CACHE STRING "" FORCE)

string(REPLACE  "-fstack-protector-strong"  ""  CCWS_CXX_FLAGS  "${CCWS_CXX_FLAGS}")

# should be enabled selectively, otherwise is going to fail on 3rd party software
#set(CMAKE_CXX_CLANG_TIDY "${CCWS_CLANG_TIDY}" CACHE STRING "" FORCE)

# This profile uses clang compiler (set in setup.bash) and some of the warnings should be disabled, e.g.
# -Wgnu-zero-variadic-macro-arguments -> gtest, https://github.com/google/googletest/issues/1419
set(GTEST_WARNINGS "-Wno-unknown-warning-option -Wno-deprecated-copy -Werror=extra-tokens -Wno-delete-non-abstract-non-virtual-dtor -Wno-gnu-zero-variadic-macro-arguments")
string(FIND "${CMAKE_CXX_FLAGS}" "-Wno-deprecated-copy" FIND_RESULT)
if(${FIND_RESULT} EQUAL -1) # prevent command line growth on rebuild
    # CCWS_CXX_FLAGS is used optionally, so we set CMAKE_CXX_FLAGS as well
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${GTEST_WARNINGS}" CACHE STRING "" FORCE)
    set(CCWS_CXX_FLAGS "${CCWS_CXX_FLAGS} ${GTEST_WARNINGS}" CACHE STRING "" FORCE)
endif ()

