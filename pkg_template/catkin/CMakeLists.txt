cmake_minimum_required(VERSION 3.0.0)
project(@@PACKAGE@@)

## Find catkin macros and libraries
## if COMPONENTS list like find_package(catkin REQUIRED COMPONENTS xyz)
## is used, also find other catkin packages
find_package(catkin REQUIRED)
#find_package(catkin REQUIRED COMPONENTS ...)

## System dependencies are found with CMake's conventions
#find_package(Boost REQUIRED COMPONENTS system)


## Uncomment this if the package has a setup.py. This macro ensures
## modules and global scripts declared therein get installed
## See http://ros.org/doc/api/catkin/html/user_guide/setup_dot_py.html
#catkin_python_setup()

################################################
## Declare ROS messages, services and actions ##
################################################

## To declare and build messages, services or actions from within this
## package, follow these steps:
## * Let MSG_DEP_SET be the set of packages whose message types you use in
##   your messages/services/actions (e.g. std_msgs, actionlib_msgs, ...).
## * In the file package.xml:
##   * add a build_depend tag for "message_generation"
##   * add a build_depend and a exec_depend tag for each package in MSG_DEP_SET
##   * If MSG_DEP_SET isn't empty the following dependency has been pulled in
##     but can be declared for certainty nonetheless:
##     * add a exec_depend tag for "message_runtime"
## * In this file (CMakeLists.txt):
##   * add "message_generation" and every package in MSG_DEP_SET to
##     find_package(catkin REQUIRED COMPONENTS ...)
##   * add "message_runtime" and every package in MSG_DEP_SET to
##     catkin_package(CATKIN_DEPENDS ...)
##   * uncomment the add_*_files sections below as needed
##     and list every .msg/.srv/.action file to be processed
##   * uncomment the generate_messages entry below
##   * add every package in MSG_DEP_SET to generate_messages(DEPENDENCIES ...)

## Generate messages in the 'msg' folder
#add_message_files(
#    FILES
#    Message1.msg
#    Message2.msg
#)

## Generate services in the 'srv' folder
#add_service_files(
#    FILES
#    Service1.srv
#    Service2.srv
#)

## Generate actions in the 'action' folder
#add_action_files(
#    FILES
#    Action1.action
#    Action2.action
#)

## Generate added messages and services with any dependencies listed here
#generate_messages(
#    DEPENDENCIES
#    std_msgs  # Or other packages containing msgs
#)

################################################
## Declare ROS dynamic reconfigure parameters ##
################################################

## To declare and build dynamic reconfigure parameters within this
## package, follow these steps:
## * In the file package.xml:
##   * add a build_depend and a exec_depend tag for "dynamic_reconfigure"
## * In this file (CMakeLists.txt):
##   * add "dynamic_reconfigure" to
##     find_package(catkin REQUIRED COMPONENTS ...)
##   * uncomment the "generate_dynamic_reconfigure_options" section below
##     and list every .cfg file to be processed

## Generate dynamic reconfigure parameters in the 'cfg' folder
#generate_dynamic_reconfigure_options(
#    cfg/DynReconf1.cfg
#    cfg/DynReconf2.cfg
#)

###################################
## catkin specific configuration ##
###################################
## The catkin_package macro generates cmake config files for your package
## Declare things to be passed to dependent projects
## INCLUDE_DIRS: uncomment this if your package contains header files
## LIBRARIES: libraries you create in this project that dependent projects also need
## CATKIN_DEPENDS: catkin_packages dependent projects also need
## DEPENDS: system dependencies of this project that dependent projects also need
catkin_package(
#    INCLUDE_DIRS include
#    LIBRARIES ${PROJECT_NAME}
#    CATKIN_DEPENDS ...
#    DEPENDS system_lib
)

###########
## Build ##
###########

## --------------
## CCWS flags
## --------------
#if (CCWS_CLANG_TIDY)
#    set (CMAKE_CXX_CLANG_TIDY "${CCWS_CLANG_TIDY}")
#endif()
#if (CCWS_CXX_FLAGS)
#    set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${CCWS_CXX_FLAGS}")
#    set (CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} ${CCWS_LINKER_FLAGS}")
#endif()
#add_definitions(-DCCWS_DEBUG=${CCWS_DEBUG})
#add_definitions(-DCCWS_BUILD_PROFILE="${CCWS_BUILD_PROFILE}")
## --------------

## Specify additional locations of header files
## Your package locations should be listed before other locations
include_directories(
#    include
#    SYSTEM ${catkin_INCLUDE_DIRS}
)

## Declare a C++ library
#add_library(${PROJECT_NAME}
#    src/${PROJECT_NAME}/${PROJECT_NAME}.cpp
#)

## Add cmake target dependencies of the library
## as an example, code may need to be generated before libraries
## either from message generation or dynamic reconfigure
#add_dependencies(${PROJECT_NAME} ${${PROJECT_NAME}_EXPORTED_TARGETS} ${catkin_EXPORTED_TARGETS})

## Declare a C++ executable
## With catkin_make all packages are built within a single CMake context
## The recommended prefix ensures that target names across packages don't collide
#add_executable(${PROJECT_NAME}_node src/${PROJECT_NAME}_node.cpp)

## Rename C++ executable without prefix
## The above recommended prefix causes long target names, the following renames the
## target back to the shorter version for ease of user use
## e.g. "rosrun someones_pkg node" instead of "rosrun someones_pkg someones_pkg_node"
#set_target_properties(${PROJECT_NAME}_node PROPERTIES OUTPUT_NAME node PREFIX "")

## Add cmake target dependencies of the executable
## same as for the library above
#add_dependencies(${PROJECT_NAME}_node ${${PROJECT_NAME}_EXPORTED_TARGETS} ${catkin_EXPORTED_TARGETS})

## Specify libraries to link a library or executable target against
#target_link_libraries(${PROJECT_NAME}_node
#    ${catkin_LIBRARIES}
#)

#############
## Install ##
#############

# all install targets should use catkin DESTINATION variables
# See http://ros.org/doc/api/catkin/html/adv_user_guide/variables.html

## Mark executable scripts (Python etc.) for installation
## in contrast to setup.py, you can choose the destination
#install(PROGRAMS
#    scripts/my_python_script
#    DESTINATION ${CATKIN_PACKAGE_BIN_DESTINATION}
#)

## Mark executables and/or libraries for installation
#install(TARGETS ${PROJECT_NAME} ${PROJECT_NAME}_node
#    ARCHIVE DESTINATION ${CATKIN_PACKAGE_LIB_DESTINATION}
#    LIBRARY DESTINATION ${CATKIN_PACKAGE_LIB_DESTINATION}
#    RUNTIME DESTINATION ${CATKIN_PACKAGE_BIN_DESTINATION}
#)

## Mark cpp header files for installation
#install(DIRECTORY include/${PROJECT_NAME}/
#    DESTINATION ${CATKIN_PACKAGE_INCLUDE_DESTINATION}
#    FILES_MATCHING PATTERN "*.h"
#)

## Mark other files for installation (e.g. launch and bag files, etc.)
#install(FILES
#    # myfile1
#    # myfile2
#    DESTINATION ${CATKIN_PACKAGE_SHARE_DESTINATION}
#)
#foreach(DIR launch config)
#    install(DIRECTORY ${DIR}
#        DESTINATION ${CATKIN_PACKAGE_SHARE_DESTINATION}
#        USE_SOURCE_PERMISSIONS
#    )
#endforeach()
#file(GLOB_RECURSE ${PROJECT_NAME}_scripts RELATIVE ${CMAKE_SOURCE_DIR} "scripts/*")
#if (${PROJECT_NAME}_scripts)
#    install(PROGRAMS ${${PROJECT_NAME}_scripts}
#        DESTINATION ${CATKIN_PACKAGE_BIN_DESTINATION}
#    )
#endif()
#install(FILES ${CMAKE_SOURCE_DIR}/plugin.xml
#    DESTINATION ${CATKIN_PACKAGE_SHARE_DESTINATION}
#)

# systemd units
#if (DEFINED ENV{CCWS_SYSTEMD_UNIT_INSTALL_DIR})
#    install(FILES
#        ${CMAKE_CURRENT_LIST_DIR}/systemd/example.service
#        DESTINATION $ENV{CCWS_SYSTEMD_UNIT_INSTALL_DIR}
#    )
#endif()

# udev rules
#if (DEFINED ENV{CCWS_UDEV_RULE_INSTALL_DIR})
#    install(FILES
#        ${CMAKE_CURRENT_LIST_DIR}/udev/99-example.rules
#        DESTINATION $ENV{CCWS_UDEV_RULE_INSTALL_DIR}
#    )
#endif()


#----------------------------------------------
# Uncomment to enable tests.
#----------------------------------------------
# It is recommended to introduce vendor specific testing flag for finer control.
#if(CATKIN_ENABLE_TESTING OR CCWS_ENABLE_TESTING)
#    if (NOT TARGET gmock)
#        find_package(GMock REQUIRED)
#    endif()
#    add_subdirectory(test)
#endif()
#----------------------------------------------
