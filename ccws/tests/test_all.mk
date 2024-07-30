test:
	${MAKE} -f ccws/tests/test_conan.mk
	${MAKE} -f ccws/tests/test_main.mk
	${MAKE} -f ccws/tests/test_cross.mk BUILD_PROFILE=cross_raspberry_pi ROS_DISTRO=melodic
	${MAKE} -f ccws/tests/test_cross.mk BUILD_PROFILE=cross_jetson_xavier ROS_DISTRO=melodic
	${MAKE} -f ccws/tests/test_cross.mk BUILD_PROFILE=cross_jetson_nano ROS_DISTRO=melodic
