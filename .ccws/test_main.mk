export ROS_DISTRO?=melodic

test:
	# reset
	${MAKE} purge
	${MAKE} host_install
	${MAKE} wsinit REPOS="https://github.com/asherikov/staticoma.git"
	# noop, just checking
	${MAKE} target_install PKG=staticoma
	# test various build profiles
	${MAKE} build_with_profile PROFILE=reldebug
	${MAKE} build_with_profile PROFILE=addr_undef_sanitizers
	${MAKE} build_with_profile PROFILE=thread_sanitizer
	${MAKE} build_with_profile PROFILE=scan_build
	# static checks & documentation
	${MAKE} host_install PROFILE=static_checks
	${MAKE} static_checks
	${MAKE} host_install PROFILE=doxygen
	${MAKE} dox PKG=staticoma
	${MAKE} doxall
	# add dependencies to the workspace and build deb package
	${MAKE} wsclean
	${MAKE} dep_to_rosinstall PKG=staticoma
	${MAKE} wsdep_to_rosinstall
	${MAKE} wsupdate
	${MAKE} deb PKG=staticoma

build_with_profile:
	${MAKE} staticoma
	${MAKE} wstest
	${MAKE} wsctest
