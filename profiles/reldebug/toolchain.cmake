include("${CMAKE_CURRENT_LIST_DIR}/../common/cmake_flags.cmake")
set(CMAKE_BUILD_TYPE            RelWithDebInfo CACHE STRING "" FORCE)

include("${CMAKE_CURRENT_LIST_DIR}/../common/cxx_flags.cmake")

# too many issues: missing dependencies, etc
set(CATKIN_ENABLE_TESTING   "OFF" CACHE STRING "" FORCE)
set(CATKIN_SKIP_TESTING     "OFF" CACHE STRING "" FORCE)
