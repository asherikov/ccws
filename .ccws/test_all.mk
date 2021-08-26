test:
	${MAKE} -f .ccws/test_main.mk
	${MAKE} -f .ccws/test_cross.mk BUILD_PROFILE=cross_raspberry_pi ROS_DISTRO=melodic
	${MAKE} -f .ccws/test_cross.mk BUILD_PROFILE=cross_jetson_xavier ROS_DISTRO=melodic
	${MAKE} -f .ccws/test_cross.mk BUILD_PROFILE=cross_jetson_nano ROS_DISTRO=melodic
