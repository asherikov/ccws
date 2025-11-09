set(CMAKE_BUILD_TYPE            RelWithDebInfo CACHE STRING "" FORCE)


###############################################################################
# compilers
###

set(CMAKE_C_COMPILER    $ENV{CC} CACHE STRING "" FORCE)
set(CMAKE_CXX_COMPILER  $ENV{CXX} CACHE STRING "" FORCE)


###############################################################################
# cmake & system
###

set(CMAKE_SYSROOT "" CACHE STRING "" FORCE)
set(CMAKE_SYSTEM_NAME Linux CACHE STRING "" FORCE)
set(CMAKE_SYSTEM_VERSION 1 CACHE STRING "" FORCE)
set(CMAKE_SYSTEM_PROCESSOR "$ENV{CCWS_TRIPLE_ARCH}" CACHE STRING "" FORCE)
set(CMAKE_LIBRARY_ARCHITECTURE "$ENV{CCWS_TRIPLE}" CACHE STRING "" FORCE)
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY CACHE STRING "" FORCE)
set(CMAKE_TOOLCHAIN_FILE $ENV{CMAKE_TOOLCHAIN_FILE} CACHE STRING "" FORCE)

set(CMAKE_FIND_ROOT_PATH "${CMAKE_INSTALL_PREFIX};${CMAKE_SYSROOT}/usr/;${CMAKE_SYSROOT}/opt/ros/$ENV{ROS_DISTRO}/" CACHE STRING "" FORCE)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY CACHE STRING "" FORCE)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY CACHE STRING "" FORCE)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY CACHE STRING "" FORCE)
# CMAKE_FIND_ROOT_PATH is not enough?
set(CMAKE_PREFIX_PATH "${CMAKE_FIND_ROOT_PATH}" CACHE STRING "" FORCE)

# Normally this should be NEVER, but we have to use python from the target,
# otherwise generated ROS scripts have wrong python paths, see
# catkin/cmake/catkin_install_python.cmake. In order to avoid performance
# decrease we bind mount host native python and other binaries (see setup
# script).
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM ONLY CACHE STRING "" FORCE)

set(CMAKE_IMPORT_LIBRARY_PREFIX ${CMAKE_SYSROOT} CACHE STRING "" FORCE)


###############################################################################
# inclusions
###

include_directories(SYSTEM "/usr/include/${CMAKE_LIBRARY_ARCHITECTURE}/")
# for some unknown reason this path gets eliminated by cmake if specified as
# '$CMAKE_SYSROOT/usr/include/', seems to be fixed in newer versions of cmake
include_directories(SYSTEM "/usr/../usr/include/")
include_directories(SYSTEM "/usr/include/c++/$ENV{CCWS_GCC_VERSION}/")


###############################################################################
# compilation flags
###


###############################################################################
# linking
###

link_directories("/usr/lib/gcc/${CMAKE_LIBRARY_ARCHITECTURE}/$ENV{CCWS_GCC_VERSION}")
# in order to make our lives more interesting cmake eliminates this path, so we
# have to set it explicitly with `-L` below
link_directories("/usr/lib/${CMAKE_LIBRARY_ARCHITECTURE}/")
link_directories("/lib/${CMAKE_LIBRARY_ARCHITECTURE}/")


# -Wl,-rpath-link,(...)/lib/
#   transitive library dependencies ignore -L flag and must be set with -rpath-link
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} \
    -L/usr/lib/${CMAKE_LIBRARY_ARCHITECTURE}/ \
    -Wl,-verbose \
    -Wl,-rpath-link,/lib/ \
    -Wl,-rpath-link,/lib/${CMAKE_LIBRARY_ARCHITECTURE} \
    -Wl,-rpath-link,/usr/lib/ \
    -Wl,-rpath-link,/usr/lib/${CMAKE_LIBRARY_ARCHITECTURE} \
    -Wl,-rpath-link,${CMAKE_INSTALL_PREFIX}/lib/ \
    -Wl,-rpath-link,${CMAKE_SYSROOT}/opt/ros/$ENV{ROS_DISTRO}/lib" CACHE STRING "" FORCE)

set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -Wl,-verbose -L/usr/lib/${CMAKE_LIBRARY_ARCHITECTURE}/" CACHE STRING "" FORCE)

