THIS_MAKEFILE=.ccws/test_main.mk

test:
	# package & profile creation
	${MAKE} bprof_new BUILD_PROFILE=test_profile BASE_BUILD_PROFILE=reldebug
	${MAKE} bprof_install_build BUILD_PROFILE=test_profile
	${MAKE} wsinit
	${MAKE} new PKG=test_pkg EMAIL=example@example.org AUTHOR=example
	${MAKE} wsscrape_all
	${MAKE} dep_to_repolist PKG=test_pkg
	${MAKE} wsupdate
	${MAKE} bprof_install_host PKG=test_pkg
	${MAKE} test_pkg BUILD_PROFILE=test_profile
	# reset
	${MAKE} purge
	${MAKE} wspurge
	${MAKE} wsinit REPOS="https://github.com/asherikov/staticoma.git"
	# add dependencies to the workspace and build deb package
	${MAKE} dep_to_repolist PKG=staticoma
	${MAKE} dep_to_repolist
	${MAKE} wsupdate
	${MAKE} bprof_install_host PKG=staticoma
	${MAKE} bprof_install_host
	${MAKE} staticoma BUILD_PROFILE=deb BASE_BUILD_PROFILE=reldebug
	# drop downloaded ROS packages, we are going to install binaries
	${MAKE} wsclean
	mv src/staticoma ./
	rm -Rf ./src/*
	mv staticoma ./src/
	${MAKE} bprof_install_host PKG=staticoma
	# test various build profiles
	${MAKE} -f ${THIS_MAKEFILE} build_with_profile BUILD_PROFILE=addr_undef_sanitizers
	${MAKE} -f ${THIS_MAKEFILE} build_with_profile BUILD_PROFILE=thread_sanitizer
	${MAKE} -f ${THIS_MAKEFILE} build_with_profile BUILD_PROFILE=scan_build
	${MAKE} -f ${THIS_MAKEFILE} build_with_profile BUILD_PROFILE=reldebug
	# check valgrind exec profile
	${MAKE} eprof_install EXEC_PROFILE=valgrind
	${MAKE} wstest PKG=staticoma EXEC_PROFILE=valgrind
	# static checks & documentation
	${MAKE} bprof_install_build BUILD_PROFILE=static_checks
	${MAKE} BUILD_PROFILE=static_checks
	${MAKE} bprof_install_build BUILD_PROFILE=doxygen
	${MAKE} PKG=staticoma BUILD_PROFILE=doxygen
	${MAKE} BUILD_PROFILE=doxygen

build_with_profile:
	${MAKE} wsclean
	${MAKE} bprof_install_build
	${MAKE} staticoma
	${MAKE} wstest
	${MAKE} wsctest
