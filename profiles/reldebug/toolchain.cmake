include("${CMAKE_CURRENT_LIST_DIR}/../common/cmake_flags.cmake")
set(CMAKE_BUILD_TYPE            RelWithDebInfo CACHE STRING "" FORCE)

include("${CMAKE_CURRENT_LIST_DIR}/../common/cxx_flags.cmake")

# tests are enabled by default, but keep in mind that there are many issues
# with tests in ROS core packages: missing dependencies, failing tests, etc.
# it is recommended to disable these and use CCWS_ENABLE_TESTING instead (see
# common/cmake_flags.cmake), or a vendor specific flag
set(CATKIN_ENABLE_TESTING   "ON"    CACHE STRING "" FORCE)
set(CATKIN_SKIP_TESTING     "OFF"   CACHE STRING "" FORCE)
