cmake_minimum_required(VERSION 3.0.0)
project(nix_test CXX)

set(CMAKE_FIND_DEBUG_MODE ON)
find_package(Eigen3 CONFIG REQUIRED)
add_executable(${PROJECT_NAME} main.cpp)
target_link_libraries(${PROJECT_NAME} Eigen3::Eigen)

