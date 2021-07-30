# this way there is no need to specify profile explicitly -- it is implied by target names
SETUP_SCRIPT_cross_jetson_xavier=source ${WORKSPACE_DIR}/profiles/cross_jetson_xavier/setup.bash

# assuming ubuntu 18.04
cross_jetson_xavier_install: cross_install_common_host_deps
	sudo apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/7fa2af80.pub
	sudo apt update
	${APT_INSTALL} \
		g++-8-aarch64-linux-gnu cuda-nvcc-10-2 \
	${MAKE} download PROFILE=cross_raspberry_pi \
		FILES="https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/cuda-repo-ubuntu1804_10.0.130-1_amd64.deb"
	bash -c "${SETUP_SCRIPT_cross_raspberry_pi}; \
		cd \"\$${CCWS_PROFILE_BUILD_DIR}\"; \
		sudo dpkg -i cuda-repo-ubuntu1804_10.0.130-1_amd64.deb"
	# 1. copy qemu in order to be able to do chroot
	# 2. NVIDIA overrides OpenCV package with version 4, but we need OpenCV 3 in melodic
	#    apt-cache policy libopencv-dev
	${MAKE} cross_jetson_xavier_mount
	-bash -c "${SETUP_SCRIPT_cross_jetson_xavier}; \
		cd \"\$${CCWS_SYSROOT}\"; \
		sudo cp /usr/bin/qemu-aarch64-static ./usr/bin/; \
		sudo chroot ./ /bin/sh -c \
			'apt remove libopencv-dev; \
			${APT_INSTALL} libopencv-dev:arm64=3.2.0+dfsg-4ubuntu0.1; \
			apt clean; '"
	${MAKE} cross_jetson_xavier_umount

cross_jetson_xavier_mount: cross_jetson_xavier_umount
	sudo bash -c "${SETUP_SCRIPT_cross_jetson_xavier}; \
		DEVICE=\$$(${CROSS_SETUP_LOOP_DEV}); \
		${MAKE} cross_sysroot_mount DEVICE=\$${DEVICE}; "

cross_jetson_xavier_umount:
	${MAKE} cross_umount PROFILE=cross_jetson_xavier
