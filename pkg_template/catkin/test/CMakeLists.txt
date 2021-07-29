find_package(rostest REQUIRED)

include_directories(SYSTEM ${catkin_INCLUDE_DIRS})


# gtest
# working directory may be useful in some cases
catkin_add_gtest(test_demo_gtest demo_gtest.cpp WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}/test)
target_link_libraries(test_demo_gtest ${catkin_LIBRARIES})

# or add executable without test.
#catkin_add_executable_with_gtest(test_demo_gtest demo_gtest.cpp)
#target_link_libraries(test_demo_gtest ${catkin_LIBRARIES})


# ROSTEST
add_rostest_gtest(test_demo_rostest demo_rostest.test demo_rostest.cpp)
target_link_libraries(test_demo_rostest ${catkin_LIBRARIES})



add_rostest(launch/demo_rostest_parametrized.test
            DEPENDENCIES test_demo_gtest
            ARGS parameter1:=parameter1 parameter2:=parameter2)

if (NOT DISABLE_EXTENDED_TESTS)
    add_rostest(launch/demo_rostest_parametrized.test
                DEPENDENCIES test_demo_gtest
                ARGS parameter1:=parameter2 parameter2:=parameter1)
endif
