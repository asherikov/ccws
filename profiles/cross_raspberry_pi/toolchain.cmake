###############################################################################
# generic cmake parameters
###
include("${CMAKE_CURRENT_LIST_DIR}/../common/cmake_flags.cmake")
set(CMAKE_BUILD_TYPE            RelWithDebInfo CACHE STRING "" FORCE)


###############################################################################
# compilers
###

set(CMAKE_CXX_COMPILER          arm-linux-gnueabihf-g++ CACHE STRING "" FORCE)
set(CMAKE_C_COMPILER            arm-linux-gnueabihf-gcc CACHE STRING "" FORCE)

set(CCW_GCC_VERSION 8)


###############################################################################
# cmake & system
###

file(TO_CMAKE_PATH "$ENV{CCW_SYSROOT}" CMAKE_SYSROOT)
set(CMAKE_SYSROOT "${CMAKE_SYSROOT}" CACHE STRING "" FORCE)
set(CMAKE_SYSTEM_NAME Linux CACHE STRING "" FORCE)
set(CMAKE_SYSTEM_VERSION 1 CACHE STRING "" FORCE)
set(CMAKE_SYSTEM_PROCESSOR "$ENV{CCW_TRIPLE_ARCH}" CACHE STRING "" FORCE)
set(CMAKE_LIBRARY_ARCHITECTURE "$ENV{CCW_TRIPLE}" CACHE STRING "" FORCE)
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY CACHE STRING "" FORCE)


# CMAKE_INSTALL_PREFIX not always equal to $ENV{CCW_ROS_ROOT}
set(CMAKE_FIND_ROOT_PATH "$ENV{CCW_COMPILER_ROOT};${CMAKE_INSTALL_PREFIX};${CMAKE_SYSROOT};$ENV{CCW_ROS_ROOT}" CACHE STRING "" FORCE)
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER CACHE STRING "" FORCE)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY CACHE STRING "" FORCE)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY CACHE STRING "" FORCE)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY CACHE STRING "" FORCE)


set(CMAKE_IMPORT_LIBRARY_PREFIX ${CMAKE_SYSROOT} CACHE STRING "" FORCE)


###############################################################################
# inclusions
###

# those should really be SYSTEM, but then they get lower priority than -I
# directories used by the packages and can be overriden by them so than the
# headers are going to be serach in the host root.
include_directories("${CMAKE_SYSROOT}/usr/include/${CMAKE_LIBRARY_ARCHITECTURE}/")
# for some unknown reason this path gets eliminated from the command line if
# used without '../usr'
include_directories("${CMAKE_SYSROOT}/usr/../usr/include/")
include_directories("${CMAKE_SYSROOT}/usr/include/c++/${CCW_GCC_VERSION}/")


###############################################################################
# compilation flags
###

# ROS:
# 1. SIP_MODULE_NAME is needed for python_orocos_kdl, was defined in python2.7/sip.h
# 2. -Wnarrowing -> issue in ros_comm/xmlrpcpp/test/test_base64.cpp
set(CCW_ROS_CXX_FLAGS "-Wno-narrowing")

# Eigen: disable alignment for simplicity
# http://eigen.tuxfamily.org/dox-devel/group__TopicUnalignedArrayAssert.html
set(CCW_EIGEN_CXX_FLAGS "-D'EIGEN_MAX_STATIC_ALIGN_BYTES=0'")

# SYSTEM
# since there is no SYSTEM in system includes above they may lead to failures
# in packages that use -Werror
set(CCW_SYSTEM_CXX_FLAGS "-Wno-error")

# force flags to cmake cache
string(FIND "${CMAKE_CXX_FLAGS}" "${CCW_ROS_CXX_FLAGS}" FIND_RESULT)
if(${FIND_RESULT} EQUAL -1) # prevent command line growth on rebuild
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${CCW_ROS_CXX_FLAGS} ${CCW_EIGEN_CXX_FLAGS}" CACHE STRING "" FORCE)
    # make sure that noerror is the last
    set(CMAKE_CXX_FLAGS_RELWITHDEBINFO "${CMAKE_CXX_FLAGS_RELWITHDEBINFO} ${CCW_SYSTEM_CXX_FLAGS}" CACHE STRING "" FORCE)
endif ()


###############################################################################
# linking
###

# ROS:
# 1. missing thread dependency in xmlrpcpp tests
set(CCW_ROS_LINKER_FLAGS "-lpthread")

link_directories("${CMAKE_SYSROOT}/usr/lib/gcc/${CMAKE_LIBRARY_ARCHITECTURE}/${CCW_GCC_VERSION}") # GCC
link_directories("${CMAKE_SYSROOT}/usr/lib/${CMAKE_LIBRARY_ARCHITECTURE}/")
link_directories("${CMAKE_SYSROOT}/lib/${CMAKE_LIBRARY_ARCHITECTURE}/")


# -Wl,-rpath-link,(...)/lib/
#   transitive library dependencies ignore -L flag and must be set with -rpath-link
#   fixes dependencies of `kdl_parser`: `class_loader`, `roslib`
# -Wl,--copy-dt-needed-entries
#   -> https://stackoverflow.com/questions/19901934/libpthread-so-0-error-adding-symbols-dso-missing-from-command-line
#   appears only in docker/buster, probably slightly different compiler version.
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} \
    -Wl,-verbose \
    -Wl,--copy-dt-needed-entries \
    -Wl,-rpath-link,${CMAKE_SYSROOT}/lib/ \
    -Wl,-rpath-link,${CMAKE_SYSROOT}/lib/${CMAKE_LIBRARY_ARCHITECTURE} \
    -Wl,-rpath-link,${CMAKE_SYSROOT}/usr/lib/ \
    -Wl,-rpath-link,${CMAKE_SYSROOT}/usr/lib/${CMAKE_LIBRARY_ARCHITECTURE} \
    -Wl,-rpath-link,${CMAKE_INSTALL_PREFIX}/lib/ \
    -Wl,-rpath-link,$ENV{CCW_ROS_ROOT}/lib" CACHE STRING "" FORCE)

set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -Wl,-verbose ${CCW_ROS_LINKER_FLAGS}" CACHE STRING "" FORCE)


