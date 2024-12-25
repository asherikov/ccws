assert_BUILD_PROFILE_must_be_cross_jetson_xavier:
	test "${CCWS_PRIMARY_BUILD_PROFILE}" = "cross_jetson_xavier"

bp_cross_jetson_xavier_install_build: cross_common_install_build bp_common_install_build assert_BUILD_PROFILE_must_be_cross_jetson_xavier
	${MAKE} cross_jetson_install_build_${OS_DISTRO_BUILD}

#bp_cross_jetson_xavier_get: assert_BUILD_PROFILE_must_be_cross_jetson_xavier

#bp_cross_jetson_xavier_initialize: assert_BUILD_PROFILE_must_be_cross_jetson_xavier
#	${MAKE} wswraptarget TARGET=private_cross_jetson_initialize_bionic

bp_cross_jetson_xavier_mount: assert_BUILD_PROFILE_must_be_cross_jetson_xavier
	${MAKE} cross_umount
	${MAKE} wswraptarget TARGET=private_cross_mount_loopback
	${MAKE} wswraptarget TARGET=private_cross_mount_specialfs

bp_cross_jetson_xavier_build: private_cross_build
	# redirection


cross_jetson_install_build_bionic:
	${MAKE} nvidia_install_build_repos DISTRO=ubuntu1804 REPO_PKG=cuda-repo-ubuntu1804_10.2.89-1_amd64.deb KEYRING_PKG=cuda-keyring_1.0-1_all.deb
	bash -c "${SETUP_SCRIPT}; \
		sudo apt update;
		sudo ${APT_INSTALL} g++-\$${CCWS_GCC_VERSION}-aarch64-linux-gnu cuda-nvcc-10-2 device-tree-compiler cpio"

private_cross_jetson_initialize_bionic:
	# XXX NVIDIA overrides OpenCV package with version 4, but ROS melodic needs
	# OpenCV 3 see `apt-cache policy libopencv-dev`
	# apt purge --yes libopencv-dev
	# apt install libopencv-dev:arm64=3.2.0+dfsg-4ubuntu0.1
	${MAKE} private_cross_jetson_initialize_generic DISTRO=ubuntu1804 KEYRING_PKG=cuda-keyring_1.0-1_all.deb


private_cross_jetson_initialize_generic:
	# 1. copy qemu in order to be able to do chroot
	# 2. 'wget -qO - https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | sudo chroot ./ apt-key add -;'
	#    may not work, using workaround from https://github.com/Microsoft/WSL/issues/3286
	sudo cp /usr/bin/qemu-aarch64-static ${CCWS_SYSROOT}/usr/bin/
	# might be necessary in some docker environments
	sudo update-binfmts --enable qemu-aarch64
	# ROS keys
	wget -qO - https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | gpg --dearmor | sudo chroot ${CCWS_SYSROOT} tee /etc/apt/trusted.gpg.d/ros.gpg > /dev/null
	echo 'deb http://packages.ros.org/ros/ubuntu ${OS_DISTRO_BUILD} main' | sudo chroot ${CCWS_SYSROOT} tee /etc/apt/sources.list.d/ros-latest.list
	# nvidia keys (we use ARCH=x86_64 since the package is not available form arm, but contains only configuration files)
	${MAKE} download FILES="https://developer.download.nvidia.com/compute/cuda/repos/${DISTRO}/x86_64/${KEYRING_PKG}"
	sudo cp ${CCWS_CACHE}/${KEYRING_PKG} ${CCWS_SYSROOT}/root/
	sudo chroot ${CCWS_SYSROOT} dpkg -i /root/${KEYRING_PKG}
	sudo rm -Rf ${CCWS_SYSROOT}/root/${KEYRING_PKG}
	# repos may be commented out
	sudo chroot ${CCWS_SYSROOT} sed -i 's/^# *deb/deb/' /etc/apt/sources.list.d/nvidia-l4t-apt-source.list

