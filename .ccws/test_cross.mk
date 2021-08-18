export PROFILE?=cross_raspberry_pi
export ROS_DISTRO?=melodic

test:
	${MAKE} purge
	${MAKE} host_install
	${MAKE} wsinit REPOS="https://github.com/asherikov/staticoma.git"
	${MAKE} dep_to_rosinstall PKG=staticoma
	${MAKE} wsdep_to_rosinstall
	${MAKE} wsupdate
	${MAKE} target_install PKG=staticoma
	${MAKE} cross_mount
	${MAKE} staticoma
	${MAKE} wsclean
	${MAKE} deb PKG=staticoma
	${MAKE} cross_umount
