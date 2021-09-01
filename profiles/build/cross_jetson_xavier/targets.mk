# this way there is no need to specify profile explicitly -- it is implied by target names
SETUP_SCRIPT_cross_jetson_xavier=source ${BUILD_PROFILES_DIR}/cross_jetson_xavier/setup.bash

# assuming ubuntu 18.04
bprof_cross_jetson_xavier_install_build: cross_common_install_build bprof_common_install_build
	sudo apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/7fa2af80.pub
	sudo apt update
	sudo ${APT_INSTALL} g++-8-aarch64-linux-gnu cuda-nvcc-10-2

bprof_cross_jetson_xavier_install_host:
	# 1. copy qemu in order to be able to do chroot
	# 2. NVIDIA overrides OpenCV package with version 4, but we need OpenCV 3 in melodic
	#    see `apt-cache policy libopencv-dev`
	${MAKE} cross_mount BUILD_PROFILE=cross_jetson_xavier
	-bash -c "${SETUP_SCRIPT_cross_jetson_xavier}; \
		cd \"\$${CCWS_SYSROOT}\"; \
		sudo cp /usr/bin/qemu-aarch64-static ./usr/bin/; \
       	wget -qO - https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc \
	        | sudo chroot ./ apt-key add -; \
		sudo chroot ./ /bin/sh -c \
			'apt remove --yes libopencv-dev; \
			${APT_INSTALL} ca-certificates; \
			${APT_INSTALL} libopencv-dev:arm64=3.2.0+dfsg-4ubuntu0.1; \
			apt clean; '"
	-${MAKE} dep_install BUILD_PROFILE=cross_jetson_xavier
	${MAKE} cross_umount BUILD_PROFILE=cross_jetson_xavier

cross_jetson_xavier_mount:
	${MAKE} cross_umount BUILD_PROFILE=cross_jetson_xavier
	sudo bash -c "${SETUP_SCRIPT_cross_jetson_xavier}; \
		DEVICE=\$$(${CROSS_SETUP_LOOP_DEV}); \
		${MAKE} cross_sysroot_mount DEVICE=\$${DEVICE}; "
