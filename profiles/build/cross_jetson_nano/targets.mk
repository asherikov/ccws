assert_BUILD_PROFILE_must_be_cross_jetson_nano:
	test "${BUILD_PROFILE}" = "cross_jetson_nano"

bp_cross_jetson_nano_install_build: cross_common_install_build bp_common_install_build assert_BUILD_PROFILE_must_be_cross_jetson_nano
	${MAKE} cross_jetson_install_build_${OS_DISTRO_BUILD}

bp_cross_jetson_nano_install_host: assert_BUILD_PROFILE_must_be_cross_jetson_nano
	${MAKE} cross_jetson_install_host_${OS_DISTRO_BUILD}

bp_cross_jetson_nano_mount: assert_BUILD_PROFILE_must_be_cross_jetson_nano
	${MAKE} cross_umount
	sudo ${MAKE} wswraptarget TARGET=private_cross_mount BUILD_PROFILE=${BUILD_PROFILE}

bp_cross_jetson_nano_build: private_cross_build
	# redirection

