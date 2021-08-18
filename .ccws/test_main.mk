export ROS_DISTRO?=melodic

test:
	# reset
	${MAKE} purge
	${MAKE} host_install
	${MAKE} wsinit REPOS="https://github.com/asherikov/staticoma.git"
	${MAKE} target_install PKG=staticoma
	# test various build profiles
	${MAKE} staticoma
	${MAKE} wstest
	${MAKE} wsctest
	${MAKE} staticoma PROFILE=addr_undef_sanitizers
	${MAKE} wstest PROFILE=addr_undef_sanitizers
	${MAKE} wsctest PROFILE=addr_undef_sanitizers
	${MAKE} staticoma PROFILE=thread_sanitizer
	${MAKE} wstest PROFILE=thread_sanitizer
	${MAKE} wsctest PROFILE=thread_sanitizer
	${MAKE} staticoma PROFILE=scan_build
	${MAKE} wstest PROFILE=scan_build
	${MAKE} wsctest PROFILE=scan_build
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
