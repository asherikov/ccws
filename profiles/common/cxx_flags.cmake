set(CMAKE_CXX_FLAGS     "-fdiagnostics-color -fPIC" CACHE STRING "" FORCE)
set(CCWS_CXX_FLAGS
    "-Wall -Wextra -Wshadow -Werror -Werror=return-type -Werror=pedantic -pedantic-errors -fPIC -fstack-protector-strong -std=c++14"
    CACHE STRING "" FORCE)

add_definitions(-DCCWS_BUILD_PROFILE="${CCWS_BUILD_PROFILE}")
add_definitions(-DCCWS_DEBUG="${CCWS_DEBUG}")
