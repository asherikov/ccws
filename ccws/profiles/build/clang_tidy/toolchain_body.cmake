set(CMAKE_BUILD_TYPE            RelWithDebInfo CACHE STRING "" FORCE)
# disable optimization to increase compilation speed
set(CMAKE_CXX_FLAGS_RELWITHDEBINFO "-O0" CACHE STRING "" FORCE)

find_program(CCWS_CLANG_TIDY_EXECUTABLE NAMES clang-tidy-$ENV{CCWS_LLVM_VERSION} REQUIRED)

set(CMAKE_CXX_COMPILER  clang++-$ENV{CCWS_LLVM_VERSION} CACHE STRING "" FORCE)
set(CMAKE_C_COMPILER    clang-$ENV{CCWS_LLVM_VERSION}   CACHE STRING "" FORCE)

set(CCWS_CLANG_TIDY "${CCWS_CLANG_TIDY_EXECUTABLE};--config-file=$ENV{BUILD_PROFILES_DIR}/clang_tidy/clang_tidy_config.yaml;--header-filter=$ENV{WORKSPACE_SRC}/.*")

set(CCWS_CLANG_TIDY "${CCWS_CLANG_TIDY}" CACHE STRING "" FORCE)

# should be enabled selectively, otherwise is going to fail on 3rd party software
#set(CMAKE_CXX_CLANG_TIDY "${CCWS_CLANG_TIDY}" CACHE STRING "" FORCE)
