assert_BUILD_PROFILE_must_be_cross_raspberry_pi:
	test "${BUILD_PROFILE}" = "cross_raspberry_pi"

bp_cross_raspberry_pi_install_build: cross_common_install_build bp_cross_raspberry_pi_purge bp_common_install_build
	${MAKE} -j${JOBS} bp_cross_raspberry_pi_install_build_compiler

bp_cross_raspberry_pi_install_build_compiler: assert_BUILD_PROFILE_must_be_cross_raspberry_pi
	# gcc -> https://github.com/Pro/raspi-toolchain/
	${MAKE} download FILES="https://github.com/Pro/raspi-toolchain/releases/download/v1.0.2/raspi-toolchain.tar.gz"
	bash -c "${SETUP_SCRIPT}; \
		cd \"\$${CCWS_BUILD_PROFILE_DIR}\"; \
		tar -xf '${WORKSPACE_DIR}/cache/raspi-toolchain.tar.gz'"

bp_cross_raspberry_pi_get: assert_BUILD_PROFILE_must_be_cross_raspberry_pi
	# raspios -> http://downloads.raspberrypi.org/
	# the only reason we don't use lite image is that it doesn't have enough
	# space to install ROS dependencies, it is possible to resize it, but not
	# necessary for this demo
	${MAKE} download FILES="http://downloads.raspberrypi.org/raspios_armhf/images/raspios_armhf-2021-05-28/2021-05-07-raspios-buster-armhf.zip"
	bash -c "${SETUP_SCRIPT}; unzip -p '${WORKSPACE_DIR}/cache/2021-05-07-raspios-buster-armhf.zip' > \"\$${CCWS_BUILD_PROFILE_DIR}/system.img\""


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
       	wget -qO - https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc \
	        | sudo chroot ./ apt-key add -; \
    	sudo chroot ./ /bin/sh -c \"\
            echo 'deb http://packages.ros.org/ros/ubuntu' > /tmp/ros-latest.list; \
            lsb_release -sc                               >> /tmp/ros-latest.list; \
            echo 'main'                                   >> /tmp/ros-latest.list; \
            cat /tmp/ros-latest.list | paste -s -d ' ' > /etc/apt/sources.list.d/ros-latest.list; \
            rm  /tmp/ros-latest.list; \
			apt purge --yes chromium-browser libgl1-mesa-dri git realvnc-vnc-server; \
			apt clean; \
			apt update; \
			apt --yes upgrade; \
			apt clean\" "


bp_cross_raspberry_pi_mount: assert_BUILD_PROFILE_must_be_cross_raspberry_pi
	${MAKE} cross_umount
	${MAKE} wswraptarget TARGET=private_cross_mount SYSROOT_PARTITION=p2

bp_cross_raspberry_pi_purge: assert_BUILD_PROFILE_must_be_cross_raspberry_pi
	${MAKE} cross_umount
	bash -c "${SETUP_SCRIPT}; \
		rm -Rf \"\$${CCWS_BUILD_PROFILE_DIR}/system.img\"; \
		rm -Rf \"\$${CCWS_BUILD_PROFILE_DIR}/cross-pi-gcc\" "

bp_cross_raspberry_pi_build: private_cross_build
	# redirection

