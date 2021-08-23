include("${CMAKE_CURRENT_LIST_DIR}/../common/toolchain_header.cmake")
set(CMAKE_BUILD_TYPE            RelWithDebInfo CACHE STRING "" FORCE)
# disable optimization to increase compilation speed
set(CMAKE_CXX_FLAGS_RELWITHDEBINFO "-O0 -DNDEBUG" CACHE STRING "" FORCE)

set(CMAKE_CXX_COMPILER /usr/share/clang/scan-build-10/libexec/c++-analyzer  CACHE STRING "" FORCE)
set(CMAKE_C_COMPILER /usr/share/clang/scan-build-10/libexec/ccc-analyzer  CACHE STRING "" FORCE)


find_program(CCWS_CLANG_TIDY_EXECUTABLE NAMES clang-tidy-10 clang-tidy-9 clang-tidy-8 REQUIRED)

set(CCWS_CLANG_TIDY "${CCWS_CLANG_TIDY_EXECUTABLE};-warnings-as-errors=*;-checks=*")

# too annoying
set(CCWS_CLANG_TIDY "${CCWS_CLANG_TIDY},-llvm-include-order")
# do not enforce auto
set(CCWS_CLANG_TIDY "${CCWS_CLANG_TIDY},-modernize-use-trailing-return-type,-hicpp-use-auto,-modernize-use-auto")
# do not enforce capitalization of literal suffix, e.g., x = 1u -> x = 1U.
set(CCWS_CLANG_TIDY "${CCWS_CLANG_TIDY},-readability-uppercase-literal-suffix,-hicpp-uppercase-literal-suffix")
# allow function arguments with default values
set(CCWS_CLANG_TIDY "${CCWS_CLANG_TIDY},-fuchsia-default-arguments,-fuchsia-default-arguments-calls,-fuchsia-default-arguments-declarations")
# member variables can be public/protected
set(CCWS_CLANG_TIDY "${CCWS_CLANG_TIDY},-cppcoreguidelines-non-private-member-variables-in-classes,-misc-non-private-member-variables-in-classes")
# member initialization in constructors -- false positives
set(CCWS_CLANG_TIDY "${CCWS_CLANG_TIDY},-cppcoreguidelines-pro-type-member-init,-hicpp-member-init")
# default member initialization scatters initializations -- initialization must be done via constructors
set(CCWS_CLANG_TIDY "${CCWS_CLANG_TIDY},-modernize-use-default-member-init")
# calling virtual functions from desctructors is well defined and generally safe
set(CCWS_CLANG_TIDY "${CCWS_CLANG_TIDY},-clang-analyzer-optin.cplusplus.VirtualCall")
# these checks require values to be assigned to const variables, which is inconvenient
set(CCWS_CLANG_TIDY "${CCWS_CLANG_TIDY},-cppcoreguidelines-avoid-magic-numbers,-readability-magic-numbers")
# I use access specifiers (public/protected/private) to group members
set(CCWS_CLANG_TIDY "${CCWS_CLANG_TIDY},-readability-redundant-access-specifiers")
# issues on many macro
set(CCWS_CLANG_TIDY "${CCWS_CLANG_TIDY},-cppcoreguidelines-pro-type-vararg,-hicpp-vararg")
# there is no from_string
set(CCWS_CLANG_TIDY "${CCWS_CLANG_TIDY},-boost-use-to-string")
# too common
set(CCWS_CLANG_TIDY "${CCWS_CLANG_TIDY},-cppcoreguidelines-pro-bounds-array-to-pointer-decay,-hicpp-no-array-decay")

# overly restrictive fuchsia stuff
set(CCWS_CLANG_TIDY "${CCWS_CLANG_TIDY},-fuchsia-overloaded-operator,-fuchsia-multiple-inheritance,-fuchsia-statically-constructed-objects")
# overly restrictive cppcoreguidelines stuff
set(CCWS_CLANG_TIDY "${CCWS_CLANG_TIDY},-cppcoreguidelines-macro-usage")
# llvmlibc stuff
set(CCWS_CLANG_TIDY "${CCWS_CLANG_TIDY},-llvmlibc-*")

# suppress issues with gtest/gmock macro, alternatively NOLINT can be used for each macro
set(CCWS_CLANG_TIDY "${CCWS_CLANG_TIDY},-hicpp-special-member-functions,-cppcoreguidelines-special-member-functions")
set(CCWS_CLANG_TIDY "${CCWS_CLANG_TIDY},-cppcoreguidelines-owning-memory")
set(CCWS_CLANG_TIDY "${CCWS_CLANG_TIDY},-cert-err58-cpp")


set(CCWS_CLANG_TIDY "${CCWS_CLANG_TIDY}" CACHE STRING "" FORCE)

#set(CMAKE_CXX_CLANG_TIDY "${CCWS_CLANG_TIDY}" CACHE STRING "" FORCE)

include("${CMAKE_CURRENT_LIST_DIR}/../common/cxx_flags.cmake")
# This profile uses clang compiler (set in setup.bash) and some of the warnings should be disabled, e.g.
# -Wgnu-zero-variadic-macro-arguments -> gtest, https://github.com/google/googletest/issues/1419
set(CCWS_CXX_FLAGS "${CCWS_CXX_FLAGS} -Werror=extra-tokens -Wno-delete-non-abstract-non-virtual-dtor -Wno-gnu-zero-variadic-macro-arguments" CACHE STRING "" FORCE)
# fails on gtest
set(CCWS_CXX_FLAGS "${CCWS_CXX_FLAGS} -Wno-deprecated-copy" CACHE STRING "" FORCE)

include("${CMAKE_CURRENT_LIST_DIR}/../common/toolchain_footer.cmake")
