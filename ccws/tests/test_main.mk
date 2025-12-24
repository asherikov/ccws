THIS_MAKEFILE=ccws/tests/test_main.mk
TEST_SOURCE_DIR?=src

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
	${MAKE} dep_to_repolist PKG=test_pkg
	${MAKE} wsupdate_shallow
	${MAKE} log_output TARGET=wsstatus
	${MAKE} dep_install PKG=test_pkg
	${MAKE} test_pkg BUILD_PROFILE=test_profile
	# ---
	${MAKE} -f ${THIS_MAKEFILE} test_dependencies
	${MAKE} -f ${THIS_MAKEFILE} test_deb
	${MAKE} -f ${THIS_MAKEFILE} test_cmake_toolchain
	# ---
	# test various build profiles
	${MAKE} -f ${THIS_MAKEFILE} build_with_profile BUILD_PROFILE=addr_undef_sanitizers
	${MAKE} -f ${THIS_MAKEFILE} build_with_profile BUILD_PROFILE=thread_sanitizer
	${MAKE} -f ${THIS_MAKEFILE} build_with_profile BUILD_PROFILE=clang_tidy
	${MAKE} -f ${THIS_MAKEFILE} build_with_profile BUILD_PROFILE=scan_build
	${MAKE} -f ${THIS_MAKEFILE} build_with_profile BUILD_PROFILE=reldebug
	# ---
	# clangd
	${MAKE} bp_install_build BUILD_PROFILE=clangd
	${MAKE} BUILD_PROFILE=clangd BASE_BUILD_PROFILE=reldebug
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
	${MAKE} PKG=staticoma BUILD_PROFILE=doxygen
	${MAKE} BUILD_PROFILE=doxygen
	${MAKE} graph PKG=staticoma
	${MAKE} graph
	${MAKE} graph_reverse PKG=staticoma
	${MAKE} cache_clean
	# ---
	# cppcheck
	cp -R ccws/examples/.ccws "${TEST_SOURCE_DIR}"
	${MAKE} bp_install_build BUILD_PROFILE=cppcheck
	${MAKE} BUILD_PROFILE=cppcheck BASE_BUILD_PROFILE=reldebug
	rm -Rf "${TEST_SOURCE_DIR}/.ccws"
	# ---
	# static checks
	${MAKE} bp_install_build BUILD_PROFILE=static_checks
	# must fail without exceptions
	! ${MAKE} BUILD_PROFILE=static_checks
	# must succeed with exceptions
	cp -R ccws/examples/.ccws "${TEST_SOURCE_DIR}"
	${MAKE} BUILD_PROFILE=static_checks
	# must succeed without package exceptions
	rm "${TEST_SOURCE_DIR}/.ccws/static_checks.exceptions.packages"
	${MAKE} BUILD_PROFILE=static_checks

test_dependencies:
	# reset
	${MAKE} bp_purge
	${MAKE} wspurge
	${MAKE} wsinit REPOS="https://github.com/asherikov/staticoma.git"
	${MAKE} set_repo_version REPO="https://github.com/asherikov/staticoma.git" VERSION="master"
	${MAKE} rm REPO="https://github.com/asherikov/staticoma.git"
	${MAKE} add REPO="https://github.com/asherikov/staticoma.git" VERSION="master"
	# ---
	# add dependencies to the workspace and build deb package
	${MAKE} dep_to_repolist
	${MAKE} wsupdate_shallow
	${MAKE} dep_install CCWS_DEP_TYPE=build
	${MAKE} dep_install

test_deb:
	${MAKE} bp_install_build BUILD_PROFILE=deb
	${MAKE} staticoma BUILD_PROFILE=deb BASE_BUILD_PROFILE=reldebug
	${MAKE} deb_lint PKG=staticoma BUILD_PROFILE=deb BASE_BUILD_PROFILE=reldebug
	sudo dpkg -i artifacts/*/*.deb
	dpkg --get-selections | grep staticoma | cut -f 1 |  xargs sudo apt purge --yes
	# ---
	# drop downloaded ROS packages, we are going to install binaries
	${MAKE} wsclean
	mv "${TEST_SOURCE_DIR}/staticoma" ./
	rm -Rf "${TEST_SOURCE_DIR}"/*
	mv staticoma "${TEST_SOURCE_DIR}"
	${MAKE} dep_install

test_cmake_toolchain:
	# workspace cmake toolchain
	cp -R ccws/examples/.ccws "${TEST_SOURCE_DIR}/"
	echo 'message(FATAL_ERROR "toolchain inclusion")' > "${TEST_SOURCE_DIR}/.ccws/toolchain.cmake"
	# should fail
	! ${MAKE} staticoma
	rm -Rf "${TEST_SOURCE_DIR}/.ccws"

build_with_profile:
	${MAKE} wsclean
	${MAKE} bp_install_build
	${MAKE} build_all
	${MAKE} staticoma
	${MAKE} wstest
	${MAKE} wsctest
	# test recursively
	${MAKE} test_with_deps PKG=staticoma
	${MAKE} ctest_with_deps PKG=staticoma
