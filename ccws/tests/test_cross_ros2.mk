export BUILD_PROFILE?=cross_arm64
export IMAGE?=ros:jazzy-ros-base-noble

test:
	${MAKE} bp_purge
	${MAKE} wspurge
	${MAKE} bp_install_build
	${MAKE} wsinit REPOS="https://github.com/asherikov/pjmsg_mcap_wrapper.git"
	${MAKE} wsupdate_shallow
	${MAKE} cross_install PKG=pjmsg_mcap_wrapper CCWS_CROSS_HOST_PYTHON=YES IMAGE=${IMAGE}
	${MAKE} cross_mount
	${MAKE} cross_python_soabi
	${MAKE} pjmsg_mcap_wrapper
	${MAKE} wsclean
	${MAKE} bp_install_build BUILD_PROFILE=deb
	${MAKE} PKG=pjmsg_mcap_wrapper BUILD_PROFILE=deb,${BUILD_PROFILE}
	${MAKE} deb_lint PKG=pjmsg_mcap_wrapper BUILD_PROFILE=deb,${BUILD_PROFILE}
	${MAKE} cross_umount
	# alternative root extraction
	${MAKE} docker_install
	docker pull --platform linux/arm64 ros:jazzy-ros-base-noble
	${MAKE} docker_export_local IMAGE=${IMAGE}
