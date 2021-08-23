THIS_MAKEFILE=.ccws/test_main.mk

test:
	# reset
	${MAKE} purge
	${MAKE} install_build
	${MAKE} wsinit REPOS="https://github.com/asherikov/staticoma.git"
	# add dependencies to the workspace and build deb package
	${MAKE} dep_to_repolist PKG=staticoma
	${MAKE} dep_to_repolist
	${MAKE} wsupdate
	${MAKE} install_host PKG=staticoma
	${MAKE} install_host
	${MAKE} deb PKG=staticoma
	# drop downloaded ROS packages, we are going to install binaries
	${MAKE} wsclean
	mv src/staticoma ./
	rm -Rf ./src/*
	mv staticoma ./src/
	${MAKE} install_host PKG=staticoma
	# test various build profiles
	${MAKE} -f ${THIS_MAKEFILE} build_with_profile PROFILE=reldebug
	${MAKE} -f ${THIS_MAKEFILE} build_with_profile PROFILE=addr_undef_sanitizers
	${MAKE} -f ${THIS_MAKEFILE} build_with_profile PROFILE=thread_sanitizer
	${MAKE} -f ${THIS_MAKEFILE} build_with_profile PROFILE=scan_build
	# static checks & documentation
	${MAKE} install_build PROFILE=static_checks
	${MAKE} static_checks
	${MAKE} install_build PROFILE=doxygen
	${MAKE} dox PKG=staticoma
	${MAKE} doxall

build_with_profile:
	${MAKE} install_build
	${MAKE} staticoma
	${MAKE} wstest
	${MAKE} wsctest
