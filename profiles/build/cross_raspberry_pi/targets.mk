# this way there is no need to specify profile explicitly -- it is implied by target names
SETUP_SCRIPT_cross_raspberry_pi=source ${BUILD_PROFILES_DIR}/cross_raspberry_pi/setup.bash

bprof_cross_raspberry_pi_install_build: cross_common_install_build cross_raspberry_pi_clean bprof_common_install_build
	# gcc -> https://github.com/Pro/raspi-toolchain/
	# raspios -> http://downloads.raspberrypi.org/
	# the only reason we don't use lite image is that it doesn't have enough
	# space to install ROS dependencies, it is possible to resize it, but not
	# necessary for this demo
	${MAKE} wsclean_build BUILD_PROFILE=cross_raspberry_pi
	${MAKE} download BUILD_PROFILE=cross_raspberry_pi \
		FILES="https://github.com/Pro/raspi-toolchain/releases/download/v1.0.2/raspi-toolchain.tar.gz \
				http://downloads.raspberrypi.org/raspios_armhf/images/raspios_armhf-2021-05-28/2021-05-07-raspios-buster-armhf.zip"
	bash -c "${SETUP_SCRIPT_cross_raspberry_pi}; \
		cd \"\$${CCWS_BUILD_DIR}\"; \
		tar -xf raspi-toolchain.tar.gz; \
		unzip -o 2021-05-07-raspios-buster-armhf.zip; \
		mv cross-pi-gcc \"\$${CCWS_BUILD_PROFILE_DIR}\"; \
		mv 2021-05-07-raspios-buster-armhf.img \"\$${CCWS_BUILD_PROFILE_DIR}/system.img\""

bprof_cross_raspberry_pi_install_host:
	# 1. copy qemu in order to be able to do chroot
	# 2. add ROS apt sources in order to avoid weird package conflicts,
	#    e.g., lack of catkin_pkg_modules in upstream repos.
	#    https://github.com/ros-infrastructure/catkin_pkg/issues/298
	#    http://wiki.ros.org/UpstreamPackages
	#    apt-cache showpkg python-catkin-pkg
	# 3. remove some heavy packages to get free space for ROS dependencies
	${MAKE} cross_mount BUILD_PROFILE=cross_raspberry_pi
	-bash -c "${SETUP_SCRIPT_cross_raspberry_pi}; \
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
	-${MAKE} dep_install BUILD_PROFILE=cross_raspberry_pi
	${MAKE} cross_umount BUILD_PROFILE=cross_raspberry_pi

cross_raspberry_pi_mount:
	${MAKE} cross_umount BUILD_PROFILE=cross_raspberry_pi
	sudo bash -c "${SETUP_SCRIPT_cross_raspberry_pi}; \
		DEVICE=\$$(${CROSS_SETUP_LOOP_DEV}); \
		${MAKE} cross_sysroot_mount DEVICE=\$${DEVICE}p2; "

cross_raspberry_pi_purge:
	${MAKE} cross_umount BUILD_PROFILE=cross_raspberry_pi
	bash -c "${SETUP_SCRIPT_cross_raspberry_pi}; \
		rm -Rf \"\$${CCWS_BUILD_PROFILE_DIR}/system.img\"; \
		rm -Rf \"\$${CCWS_BUILD_PROFILE_DIR}/cross-pi-gcc\" "
