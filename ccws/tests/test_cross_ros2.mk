export BUILD_PROFILE?=cross_arm64
export IMAGE?=ros:jazzy-ros-base-noble

test:
	${MAKE} bp_purge
	${MAKE} wspurge
	${MAKE} bp_install_build
	${MAKE} wsinit REPOS="https://github.com/asherikov/cdinit.git"
	${MAKE} wsupdate
	${MAKE} cross_install PKG=cdinit CCWS_CROSS_HOST_PYTHON=YES IMAGE=${IMAGE}
	${MAKE} cross_mount
	${MAKE} cross_python_soabi
	${MAKE} cdinit
	${MAKE} wsclean
	${MAKE} bp_install_build BUILD_PROFILE=deb
	${MAKE} PKG=cdinit BUILD_PROFILE=deb,${BUILD_PROFILE}
	${MAKE} deb_lint PKG=cdinit BUILD_PROFILE=deb,${BUILD_PROFILE}
	${MAKE} cross_umount
	# alternative root extraction
	${MAKE} docker_install
	docker pull --platform linux/arm64 ros:jazzy-ros-base-noble
	${MAKE} docker_export_local IMAGE=${IMAGE}
