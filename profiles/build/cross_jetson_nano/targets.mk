assert_BUILD_PROFILE_must_be_cross_jetson_nano:
	test "${BUILD_PROFILE}" = "cross_jetson_nano"

# assuming ubuntu 18.04
bp_cross_jetson_nano_install_build: cross_common_install_build bp_common_install_build assert_BUILD_PROFILE_must_be_cross_jetson_nano
	sudo apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/7fa2af80.pub
	sudo apt update
	sudo ${APT_INSTALL} g++-8-aarch64-linux-gnu cuda-nvcc-10-2

bp_cross_jetson_nano_install_host: assert_BUILD_PROFILE_must_be_cross_jetson_nano
	# 1. copy qemu in order to be able to do chroot
	# 2. NVIDIA overrides OpenCV package with version 4, but we need OpenCV 3 in melodic
	#    see `apt-cache policy libopencv-dev`
	${MAKE} cross_mount
	-bash -c "${SETUP_SCRIPT}; \
		cd \"\$${CCWS_SYSROOT}\"; \
		sudo cp /usr/bin/qemu-aarch64-static ./usr/bin/; \
       	wget -qO - https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc \
	        | sudo chroot ./ apt-key add -; \
		sudo chroot ./ /bin/sh -c \
			'apt update; \
			apt upgrade --yes; \
			apt remove --yes libopencv-dev; \
			${APT_INSTALL} ca-certificates; \
			${APT_INSTALL} libopencv-dev:arm64=3.2.0+dfsg-4ubuntu0.1; \
			apt clean; '"
	-${MAKE} dep_install
	${MAKE} cross_umount

bp_cross_jetson_nano_mount: assert_BUILD_PROFILE_must_be_cross_jetson_nano
	${MAKE} cross_umount
	sudo ${MAKE} wswraptarget TARGET=private_cross_mount BUILD_PROFILE=${BUILD_PROFILE}

bp_cross_jetson_nano_build: private_cross_build
	# redirection

