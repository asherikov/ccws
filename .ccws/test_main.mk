THIS_MAKEFILE=.ccws/test_main.mk
WORKSPACE_SRC?=src

test:
	# ---
	# package & profile creation
	${MAKE} wspurge
	rm -Rf profiles/build/test_profile/
	${MAKE} bp_new BUILD_PROFILE=test_profile BASE_BUILD_PROFILE=reldebug
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
	# reset
	${MAKE} bp_purge
	${MAKE} wspurge
	${MAKE} wsinit REPOS="https://github.com/asherikov/staticoma.git"
	# ---
	# add dependencies to the workspace and build deb package
	${MAKE} dep_to_repolist PKG=staticoma
	${MAKE} dep_to_repolist
	${MAKE} wsupdate
	${MAKE} dep_install PKG=staticoma
	${MAKE} dep_install
	${MAKE} bp_install_build BUILD_PROFILE=deb
	${MAKE} staticoma BUILD_PROFILE=deb BASE_BUILD_PROFILE=reldebug
	${MAKE} deb_lint PKG=staticoma BUILD_PROFILE=deb BASE_BUILD_PROFILE=reldebug
	sudo dpkg -i artifacts/*/*.deb
	dpkg --get-selections | grep staticoma | cut -f 1 |  xargs sudo apt purge --yes
	# ---
	# drop downloaded ROS packages, we are going to install binaries
	${MAKE} wsclean
	mv "${WORKSPACE_SRC}/staticoma" ./
	rm -Rf "${WORKSPACE_SRC}"/*
	mv staticoma "${WORKSPACE_SRC}"
	${MAKE} dep_install PKG=staticoma
	# ---
	# workspace cmake toolchain
	mkdir -p "${WORKSPACE_SRC}/.ccws/"
	echo 'message(FATAL_ERROR "toolchain inclusion")' > "${WORKSPACE_SRC}/.ccws/toolchain.cmake"
	# should fail
	! ${MAKE} staticoma
	rm -Rf "${WORKSPACE_SRC}/.ccws"
	# ---
	# test various build profiles
	${MAKE} -f ${THIS_MAKEFILE} build_with_profile BUILD_PROFILE=addr_undef_sanitizers
	${MAKE} -f ${THIS_MAKEFILE} build_with_profile BUILD_PROFILE=thread_sanitizer
	${MAKE} -f ${THIS_MAKEFILE} build_with_profile BUILD_PROFILE=scan_build
	${MAKE} -f ${THIS_MAKEFILE} build_with_profile BUILD_PROFILE=reldebug
	# ---
	# clangd
	${MAKE} bp_install_build BUILD_PROFILE=clangd
	${MAKE} BUILD_PROFILE=clangd BASE_BUILD_PROFILE=reldebug
	# ---
	# cppcheck
	cp -R examples/.ccws "${WORKSPACE_SRC}"
	${MAKE} bp_install_build BUILD_PROFILE=cppcheck
	${MAKE} BUILD_PROFILE=cppcheck BASE_BUILD_PROFILE=reldebug
	rm -Rf "${WORKSPACE_SRC}/.ccws"
	# ---
	# check valgrind exec profile
	${MAKE} ep_install EXEC_PROFILE=valgrind
	${MAKE} wstest EXEC_PROFILE=valgrind
	# ---
	# check core_pattern exec profile
	${MAKE} ep_install EXEC_PROFILE=core_pattern
	${MAKE} wstest EXEC_PROFILE="core_pattern valgrind"
	# ---
	# static checks
	${MAKE} bp_install_build BUILD_PROFILE=static_checks
	# must fail without exceptions
	! ${MAKE} BUILD_PROFILE=static_checks
	# must succeed with exceptions
	cp -R examples/.ccws "${WORKSPACE_SRC}"
	${MAKE} BUILD_PROFILE=static_checks
	# must succeed without package exceptions
	rm "${WORKSPACE_SRC}/.ccws/static_checks.exceptions.packages"
	${MAKE} BUILD_PROFILE=static_checks
	# ---
	# documentation
	${MAKE} bp_install_build BUILD_PROFILE=doxygen
	${MAKE} PKG=staticoma BUILD_PROFILE=doxygen
	${MAKE} BUILD_PROFILE=doxygen
	${MAKE} graph PKG=staticoma
	${MAKE} graph
	${MAKE} cache_clean
	${MAKE} wsclean

build_with_profile:
	${MAKE} wsclean
	${MAKE} bp_install_build
	${MAKE} staticoma
	${MAKE} wstest
	${MAKE} wsctest
	# test recursively
	${MAKE} test_with_deps PKG=staticoma
	${MAKE} ctest_with_deps PKG=staticoma
