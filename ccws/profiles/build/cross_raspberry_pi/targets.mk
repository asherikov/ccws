assert_BUILD_PROFILE_must_be_cross_raspberry_pi:
	test "${CCWS_PRIMARY_BUILD_PROFILE}" = "cross_raspberry_pi"

bp_cross_raspberry_pi_install_build: cross_common_install_build cross_purge install_ccws_build_deps
	${APT_INSTALL} unzip
	${MAKE} -j${JOBS} bp_cross_raspberry_pi_install_build_compiler

bp_cross_raspberry_pi_install_build_compiler: assert_BUILD_PROFILE_must_be_cross_raspberry_pi
	# gcc -> https://github.com/Pro/raspi-toolchain/
	${MAKE} download FILES="https://github.com/Pro/raspi-toolchain/releases/download/v1.0.2/raspi-toolchain.tar.gz"
	bash -c "${SETUP_SCRIPT}; \
		cd \"\$${CCWS_SYSROOT_DATA}\"; \
		tar -xf '${CCWS_CACHE}/raspi-toolchain.tar.gz'"

bp_cross_raspberry_pi_get: assert_BUILD_PROFILE_must_be_cross_raspberry_pi
	# raspios -> http://downloads.raspberrypi.org/
	# the only reason we don't use lite image is that it doesn't have enough
	# space to install ROS dependencies, it is possible to resize it, but not
	# necessary for this demo
	${MAKE} download FILES="http://downloads.raspberrypi.org/raspios_armhf/images/raspios_armhf-2021-05-28/2021-05-07-raspios-buster-armhf.zip"
	bash -c "${SETUP_SCRIPT}; unzip -p '${CCWS_CACHE}/2021-05-07-raspios-buster-armhf.zip' > \"\$${CCWS_SYSROOT_DATA}/system.img\""


bp_cross_raspberry_pi_initialize: assert_BUILD_PROFILE_must_be_cross_raspberry_pi
	# 1. copy qemu in order to be able to do chroot
	# 2. add ROS apt sources in order to avoid weird package conflicts,
	#    e.g., lack of catkin_pkg_modules in upstream repos.
	#    https://github.com/ros-infrastructure/catkin_pkg/issues/298
	#    http://wiki.ros.org/UpstreamPackages
	#    apt-cache showpkg python-catkin-pkg
	# 3. remove some heavy packages to get free space for ROS dependencies
	bash -c "${SETUP_SCRIPT}; \
		cd \"\$${CCWS_SYSROOT}\"; \
		sudo cp /usr/bin/qemu-arm-static ./usr/bin/; \
		sudo update-binfmts --enable qemu-arm; \
		wget -qO- https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | sudo tee ./etc/apt/trusted.gpg.d/ros.asc; \
    	sudo chroot ./ /bin/sh -c \"\
			( \
				echo 'deb http://packages.ros.org/ros/ubuntu' \
				&& grep VERSION_CODENAME < /etc/os-release | cut -f 2 -d '=' \
				&& echo 'main' \
			) | paste -s -d ' ' > '/etc/apt/sources.list.d/ros-latest.list'; \
			apt purge --yes chromium-browser libgl1-mesa-dri git realvnc-vnc-server libx11-6 gdb libcups2; \
			apt autoremove --yes; \
			apt clean; \
			apt update; \
			apt --yes upgrade; \
			apt clean\" "


bp_cross_raspberry_pi_mount: assert_BUILD_PROFILE_must_be_cross_raspberry_pi
	${MAKE} cross_umount
	${MAKE} wswraptarget TARGET=private_cross_mount_loopback SYSROOT_PARTITION=p2
	${MAKE} wswraptarget TARGET=private_cross_mount_specialfs

private_bp_cross_raspberry_pi_purge:
	rm -Rf "${CCWS_SYSROOT_DATA}/system.img"
	rm -Rf "${CCWS_SYSROOT_DATA}/cross-pi-gcc"

bp_cross_raspberry_pi_build: private_cross_build
	# redirection

private_bp_cross_raspberry_pi_pack: assert_BUILD_PROFILE_must_be_cross_raspberry_pi
	mkdir -p "${CCWS_ARTIFACTS_DIR}"
	cd "${CCWS_SYSROOT_DATA}"; \
		tar -cjf "${CCWS_ARTIFACTS_DIR}/${CCWS_PRIMARY_BUILD_PROFILE}_image.tar.bz2" system.img cross-pi-gcc

private_bp_cross_raspberry_pi_unpack: assert_BUILD_PROFILE_must_be_cross_raspberry_pi
	cd "${CCWS_SYSROOT_DATA}"; \
		tar -xf "${CCWS_ARTIFACTS_DIR}/${CCWS_PRIMARY_BUILD_PROFILE}_image.tar.bz2"
