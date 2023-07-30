cmake_minimum_required(VERSION 3.0.0)
project(conan_test CXX)

set(CMAKE_FIND_DEBUG_MODE ON)
find_package(conan_deps REQUIRED)
find_package(ZLIB CONFIG REQUIRED)
add_executable(${PROJECT_NAME} main.cpp)
target_link_libraries(${PROJECT_NAME} ZLIB::ZLIB)

