assert_BUILD_PROFILE_must_be_cross_jetson_xavier:
	test "${BUILD_PROFILE}" = "cross_jetson_xavier"

bp_cross_jetson_xavier_install_build: cross_common_install_build bp_common_install_build assert_BUILD_PROFILE_must_be_cross_jetson_xavier
	${MAKE} cross_jetson_install_build_${OS_DISTRO_BUILD}

#bp_cross_jetson_xavier_get: assert_BUILD_PROFILE_must_be_cross_jetson_xavier

#bp_cross_jetson_xavier_initialize: assert_BUILD_PROFILE_must_be_cross_jetson_xavier
#	${MAKE} wswraptarget TARGET=private_cross_jetson_initialize_bionic

bp_cross_jetson_xavier_mount: assert_BUILD_PROFILE_must_be_cross_jetson_xavier
	${MAKE} cross_umount
	${MAKE} wswraptarget TARGET=private_cross_mount

bp_cross_jetson_xavier_build: private_cross_build
	# redirection

