THIS_MAKEFILE=.ccws/test_main_ros2.mk

export ROS_DISTRO?=foxy


test:
	${MAKE} wspurge
	${MAKE} bprof_install_build
	${MAKE} add REPO="https://github.com/ros2/examples" VERSION="${ROS_DISTRO}"
	${MAKE} bprof_install_host PKG=examples_rclcpp_minimal_subscriber
	# deb
	${MAKE} bprof_install_build BUILD_PROFILE=deb
	${MAKE} examples_rclcpp_minimal_subscriber BUILD_PROFILE=deb BASE_BUILD_PROFILE=reldebug
	${MAKE} deb_lint PKG=examples_rclcpp_minimal_subscriber BUILD_PROFILE=deb BASE_BUILD_PROFILE=reldebug
	# test various build profiles
	${MAKE} -f ${THIS_MAKEFILE} build_with_profile BUILD_PROFILE=addr_undef_sanitizers
	${MAKE} -f ${THIS_MAKEFILE} build_with_profile BUILD_PROFILE=thread_sanitizer
	${MAKE} -f ${THIS_MAKEFILE} build_with_profile BUILD_PROFILE=scan_build
	${MAKE} -f ${THIS_MAKEFILE} build_with_profile BUILD_PROFILE=reldebug
	# documentation
	${MAKE} bprof_install_build BUILD_PROFILE=doxygen
	${MAKE} BUILD_PROFILE=doxygen


build_with_profile:
	${MAKE} wsclean
	${MAKE} bprof_install_build
	${MAKE} examples_rclcpp_minimal_subscriber
	${MAKE} test PKG=examples_rclcpp_minimal_subscriber
	${MAKE} ctest PKG=examples_rclcpp_minimal_subscriber
