export PROFILE?=cross_raspberry_pi
export ROS_DISTRO?=melodic

test:
	${MAKE} purge
	${MAKE} install
	${MAKE} cross_fetch
	${MAKE} wsinit REPOS="https://github.com/asherikov/staticoma.git"
	${MAKE} dep_to_rosinstall PKG=staticoma
	${MAKE} wsdep_to_rosinstall
	${MAKE} wsupdate
	${MAKE} cross_dep_install PKG=staticoma
	${MAKE} cross_mount
	${MAKE} staticoma
	${MAKE} wsclean
	${MAKE} deb PKG=staticoma
	${MAKE} cross_umount
