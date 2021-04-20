set(CMAKE_CXX_FLAGS     "-fdiagnostics-color -fPIC" CACHE STRING "" FORCE)
set(CCW_CXX_FLAGS
    "-Wall -Wextra -Wshadow -Werror -Werror=return-type -Werror=pedantic -pedantic-errors -fPIC -fstack-protector-strong -std=c++11"
    CACHE STRING "" FORCE)
