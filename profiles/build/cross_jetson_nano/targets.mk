assert_BUILD_PROFILE_must_be_cross_jetson_nano:
	test "${BUILD_PROFILE}" = "cross_jetson_nano"

bp_cross_jetson_nano_install_build: cross_common_install_build bp_common_install_build assert_BUILD_PROFILE_must_be_cross_jetson_nano
	${MAKE} cross_jetson_install_build_${OS_DISTRO_BUILD}

bp_cross_jetson_nano_get: assert_BUILD_PROFILE_must_be_cross_jetson_nano
	${MAKE} download FILES="https://developer.nvidia.com/embedded/l4t/r32_release_v6.1/jeston_nano/jetson-nano-jp46-sd-card-image.zip"
	${MAKE} cross_umount
	bash -c "${SETUP_SCRIPT}; unzip -p '${WORKSPACE_DIR}/cache/jetson-nano-jp46-sd-card-image.zip' > \"\$${CCWS_BUILD_PROFILE_DIR}/system.img\""

#bp_cross_jetson_nano_initialize: assert_BUILD_PROFILE_must_be_cross_jetson_nano
#	${MAKE} wswraptarget TARGET=private_cross_jetson_initialize_bionic

bp_cross_jetson_nano_mount: assert_BUILD_PROFILE_must_be_cross_jetson_nano
	${MAKE} cross_umount
	${MAKE} wswraptarget TARGET=private_cross_mount SYSROOT_PARTITION=p1

bp_cross_jetson_nano_build: private_cross_build
	# redirection


