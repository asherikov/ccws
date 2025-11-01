THIS_MAKEFILE=ccws/tests/test_main_ros2.mk
TEST_SOURCE_DIR?=src

export ROS_DISTRO?=foxy


test:
	# ---
	# package & profile creation
	${MAKE} wspurge
	rm -Rf ccws/profiles/build/test_profile/
	${MAKE} bp_new BUILD_PROFILE=test_profile,reldebug
	${MAKE} bp_install_build BUILD_PROFILE=test_profile
	${MAKE} wsinit
	${MAKE} new PKG=test_pkg EMAIL=example@example.org AUTHOR=example
	${MAKE} wsscrape_all
	${MAKE} dep_to_repolist PKG=test_pkg
	${MAKE} wsupdate
	${MAKE} log_output TARGET=wsstatus
	${MAKE} dep_install PKG=test_pkg
	${MAKE} test_pkg BUILD_PROFILE=test_profile
	# ---
	${MAKE} -f ${THIS_MAKEFILE} test_dependencies
	${MAKE} -f ${THIS_MAKEFILE} test_deb
	${MAKE} -f ${THIS_MAKEFILE} test_cmake_toolchain
	# ---
	# test various build profiles
	sudo apt install ros-${ROS_DISTRO}-ros2cli # used to test setup.bash
	${MAKE} -f ${THIS_MAKEFILE} build_with_profile BUILD_PROFILE=addr_undef_sanitizers
	${MAKE} -f ${THIS_MAKEFILE} build_with_profile BUILD_PROFILE=thread_sanitizer
	${MAKE} -f ${THIS_MAKEFILE} build_with_profile BUILD_PROFILE=scan_build
	${MAKE} -f ${THIS_MAKEFILE} build_with_profile BUILD_PROFILE=reldebug
	# ---
	# clangd
	${MAKE} bp_install_build BUILD_PROFILE=clangd,reldebug
	${MAKE} BUILD_PROFILE=clangd,reldebug
	# ---
	# check valgrind exec profile
	${MAKE} ep_install EXEC_PROFILE=valgrind
	${MAKE} wstest EXEC_PROFILE=valgrind
	# ---
	# check core_pattern exec profile
	${MAKE} ep_install EXEC_PROFILE=core_pattern
	${MAKE} wstest EXEC_PROFILE="core_pattern valgrind"
	# ---
	# documentation
	${MAKE} bp_install_build BUILD_PROFILE=doxygen
	${MAKE} PKG=examples_rclcpp_minimal_subscriber BUILD_PROFILE=doxygen
	${MAKE} BUILD_PROFILE=doxygen
	${MAKE} graph PKG=examples_rclcpp_minimal_subscriber
	${MAKE} graph
	${MAKE} graph_reverse PKG=examples_rclcpp_minimal_subscriber
	${MAKE} cache_clean
	# ---
	${MAKE} wspurge
	${MAKE} wsinit
	${MAKE} add REPO="https://github.com/asherikov/ariles.git" VERSION="pkg_ws_2"
	${MAKE} set_repo_version REPO="https://github.com/asherikov/ariles.git" VERSION="pkg_ws_2"
	${MAKE} rm REPO="https://github.com/asherikov/ariles.git"
	${MAKE} add REPO="https://github.com/asherikov/ariles.git" VERSION="pkg_ws_2"
	${MAKE} wsupdate
	${MAKE} dep_install CCWS_DEP_TYPE=build
	${MAKE} dep_install
	${MAKE} ros2param
	# ---
	# cppcheck
	cp -R ccws/examples/.ccws "${TEST_SOURCE_DIR}"
	${MAKE} bp_install_build BUILD_PROFILE=cppcheck
	${MAKE} BUILD_PROFILE=cppcheck,reldebug
	rm -Rf "${TEST_SOURCE_DIR}/.ccws"
	# ---
	# static checks
	-sudo apt purge flake8 # broken?
	-sudo python3 -m pip flake8
	-find /usr/lib/python3/ -iname "*flake8*" | xargs sudo rm -Rf
	${MAKE} bp_install_build BUILD_PROFILE=static_checks
	${MAKE} BUILD_PROFILE=static_checks

test_dependencies:
	${MAKE} bp_purge
	${MAKE} wspurge
	${MAKE} new PKG=test_dependencies
	cp -R ccws/tests/dependencies/package.xml "${TEST_SOURCE_DIR}/test_dependencies"
	${MAKE} dep_install PKG=test_dependencies
	${MAKE} wspurge
	${MAKE} add REPO="https://github.com/ros2/examples" VERSION="${ROS_DISTRO}"
	${MAKE} wsupdate
	${MAKE} dep_to_repolist
	${MAKE} dep_install
	${MAKE} wsupdate
	# ---
	# drop downloaded ROS packages, we are going to install binaries
	${MAKE} wsclean
	mv "${TEST_SOURCE_DIR}/examples" ./
	rm -Rf "${TEST_SOURCE_DIR}"/*
	mv examples "${TEST_SOURCE_DIR}"

test_deb:
	${MAKE} bp_install_build BUILD_PROFILE=deb
	${MAKE} examples_rclcpp_minimal_subscriber BUILD_PROFILE=deb,reldebug
	${MAKE} deb_lint PKG=examples_rclcpp_minimal_subscriber BUILD_PROFILE=deb,reldebug
	sudo dpkg -i artifacts/*/*.deb
	dpkg --get-selections | grep minimal-subscriber | cut -f 1 |  xargs sudo apt purge --yes

test_cmake_toolchain:
	# workspace cmake toolchain
	${MAKE} wsclean
	cp -R ccws/examples/.ccws "${TEST_SOURCE_DIR}/"
	echo 'message(FATAL_ERROR "toolchain inclusion")' > "${TEST_SOURCE_DIR}/.ccws/toolchain.cmake"
	# should fail
	! ${MAKE} examples_rclcpp_minimal_subscriber
	rm -Rf "${TEST_SOURCE_DIR}/.ccws"

build_with_profile:
	${MAKE} wsclean
	${MAKE} bp_install_build
	${MAKE} build_all
	${MAKE} examples_rclcpp_minimal_subscriber
	# workspace test
	${MAKE} wstest
	${MAKE} wsctest
	# test recursively
	${MAKE} test_with_deps PKG=examples_rclcpp_minimal_subscriber
	${MAKE} ctest_with_deps PKG=examples_rclcpp_minimal_subscriber
	# test exceptions
	cp -R ccws/examples/.ccws "${TEST_SOURCE_DIR}/"
	${MAKE} test_with_deps PKG=examples_rclcpp_minimal_subscriber
	${MAKE} ctest_with_deps PKG=examples_rclcpp_minimal_subscriber
	rm -Rf "${TEST_SOURCE_DIR}/.ccws"
	bash -c "source setup.bash && ros2"
