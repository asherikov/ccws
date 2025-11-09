assert_BUILD_PROFILE_must_be_cross_arm64:
	test "${CCWS_PRIMARY_BUILD_PROFILE}" = "cross_arm64"

bp_cross_arm64_install_build: cross_common_install_build bp_common_install_build
	${MAKE} bp_cross_arm64_install_build_${OS_DISTRO_BUILD}

bp_cross_arm64_install_build_%:
	echo "'${OS_DISTRO_BUILD}' is not supported by '${BUILD_PROFILE}'"

bp_cross_arm64_install_build_noble:
	bash -c "${SETUP_SCRIPT}; sudo ${APT_INSTALL} g++-\$${CCWS_GCC_VERSION}-aarch64-linux-gnu"

bp_cross_arm64_get:
	${MAKE} docker_mountpoint PLATFORM=arm64 IMAGE=${IMAGE}

bp_cross_arm64_initialize: assert_BUILD_PROFILE_must_be_cross_arm64
	# 1. copy qemu in order to be able to do chroot
	# 2. add ROS apt sources in order to avoid weird package conflicts,
	#    e.g., lack of catkin_pkg_modules in upstream repos.
	#    https://github.com/ros-infrastructure/catkin_pkg/issues/298
	#    http://wiki.ros.org/UpstreamPackages
	#    apt-cache showpkg python-catkin-pkg
	bash -c "${SETUP_SCRIPT}; \
		cd \"\$${CCWS_SYSROOT_MOUNTPOINT}\"; \
		sudo cp /usr/bin/qemu-aarch64-static \$${CCWS_SYSROOT_MOUNTPOINT}/usr/bin/; \
		sudo update-binfmts --enable qemu-aarch64; \
		wget -qO- https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | sudo tee ./etc/apt/trusted.gpg.d/ros.asc; \
    	sudo chroot ./ /bin/sh -c \"\
			( \
				echo 'deb [arch=amd64,arm64] http://repo.ros2.org/ubuntu/main' \
				&& grep VERSION_CODENAME < /etc/os-release | cut -f 2 -d '=' \
				&& echo 'main' \
			) | paste -s -d ' ' > '/etc/apt/sources.list.d/ros2-latest.list' \
			&& rm -f /etc/apt/apt.conf.d/docker-clean \
			&& apt update\" "

bp_cross_arm64_mount: assert_BUILD_PROFILE_must_be_cross_arm64
	${MAKE} cross_umount
	${MAKE} wswraptarget TARGET=private_cross_mount_specialfs

bp_cross_arm64_build: private_cross_build
	# redirection
