THIS_MAKEFILE=ccws/tests/test_main_ros2.mk
WORKSPACE_SRC?=src

export ROS_DISTRO?=foxy


test:
	# ---
	# package & profile creation
	${MAKE} wspurge
	rm -Rf ccws/profiles/build/test_profile/
	${MAKE} bp_new BUILD_PROFILE=test_profile BASE_BUILD_PROFILE=reldebug
	${MAKE} bp_install_build BUILD_PROFILE=test_profile
	${MAKE} wsinit
	${MAKE} new PKG=test_pkg EMAIL=example@example.org AUTHOR=example
	${MAKE} wsscrape_all
	#${MAKE} dep_to_repolist PKG=test_pkg
	${MAKE} wsupdate
	${MAKE} log_output TARGET=wsstatus
	#${MAKE} dep_install PKG=test_pkg
	#${MAKE} test_pkg BUILD_PROFILE=test_profile
	# ---
	# dependencies
	${MAKE} bp_purge
	${MAKE} wspurge
	${MAKE} bp_install_build
	${MAKE} add REPO="https://github.com/ros2/examples" VERSION="${ROS_DISTRO}"
	${MAKE} wsupdate
	${MAKE} dep_install PKG=examples_rclcpp_minimal_subscriber
	# ---
	# workspace cmake toolchain
	cp -R ccws/examples/.ccws "${WORKSPACE_SRC}/"
	echo 'message(FATAL_ERROR "toolchain inclusion")' > "${WORKSPACE_SRC}/.ccws/toolchain.cmake"
	# should fail
	! ${MAKE} examples_rclcpp_minimal_subscriber
	rm -Rf "${WORKSPACE_SRC}/.ccws"
	# ---
	# static checks
	${MAKE} bp_install_build BUILD_PROFILE=static_checks
	# ---
	# deb
	${MAKE} bp_install_build BUILD_PROFILE=deb
	${MAKE} examples_rclcpp_minimal_subscriber BUILD_PROFILE=deb BASE_BUILD_PROFILE=reldebug
	${MAKE} deb_lint PKG=examples_rclcpp_minimal_subscriber BUILD_PROFILE=deb BASE_BUILD_PROFILE=reldebug
	# ---
	# test various build profiles
	sudo apt install ros-${ROS_DISTRO}-ros2cli # used to test setup.bash
	${MAKE} -f ${THIS_MAKEFILE} build_with_profile BUILD_PROFILE=addr_undef_sanitizers
	${MAKE} -f ${THIS_MAKEFILE} build_with_profile BUILD_PROFILE=thread_sanitizer
	${MAKE} -f ${THIS_MAKEFILE} build_with_profile BUILD_PROFILE=scan_build
	${MAKE} -f ${THIS_MAKEFILE} build_with_profile BUILD_PROFILE=reldebug
	# ---
	# check valgrind exec profile
	${MAKE} ep_install EXEC_PROFILE=valgrind
	${MAKE} wstest EXEC_PROFILE=valgrind
	# ---
	# check core_pattern exec profile
	${MAKE} ep_install EXEC_PROFILE=core_pattern
	${MAKE} wstest EXEC_PROFILE="core_pattern valgrind"
	# ---
	# clangd
	${MAKE} bp_install_build BUILD_PROFILE=clangd
	${MAKE} BUILD_PROFILE=clangd BASE_BUILD_PROFILE=reldebug
	# ---
	# documentation
	${MAKE} bp_install_build BUILD_PROFILE=doxygen
	${MAKE} BUILD_PROFILE=doxygen
	${MAKE} graph PKG=examples_rclcpp_minimal_subscriber
	${MAKE} graph
	${MAKE} cache_clean
	test -z "${WORKSPACE_SRC}" || (test -d "${WORKSPACE_SRC}" && ls "${WORKSPACE_SRC}")



build_with_profile:
	${MAKE} wsclean
	${MAKE} bp_install_build
	${MAKE} examples_rclcpp_minimal_subscriber
	# workspace test
	${MAKE} wstest
	${MAKE} wsctest
	# test recursively
	${MAKE} test_with_deps PKG=examples_rclcpp_minimal_subscriber
	${MAKE} ctest_with_deps PKG=examples_rclcpp_minimal_subscriber
	bash -c "source setup.bash && ros2"
