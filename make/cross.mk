# converts absolute symlinks to relative in a mounted sysroot
# this is not needed with proot, but is necessary for some other approaches to
# cross compilation
cross_sysroot_fix_abs_symlinks:
	bash -c "${SETUP_SCRIPT}; \
		cd \"\$${CCWS_SYSROOT}\"; \
		find ./usr -lname '/*' -printf 'sudo ln --relative --symbolic --force ./%l %p\n' | /bin/sh"

# internal target, should be called with initialized environment
private_cross_mount:
	mkdir -p "${CCWS_SYSROOT}"
	losetup -PL --find --show "${CCWS_BUILD_PROFILE_DIR}/system.img" | xargs -I {} mount "{}${PARTITION}" "${CCWS_SYSROOT}"
	# resolv.conf can be a symlink to a nonexistent systemd file, in such cases
	# we have to create this file in order to use bind mounting
	test -f ${CCWS_SYSROOT}/etc/resolv.conf || touch ${CCWS_SYSROOT}/etc/resolv.conf
	mount --bind /etc/resolv.conf "${CCWS_SYSROOT}/etc/resolv.conf"
	mount --bind /dev "${CCWS_SYSROOT}/dev"
	mount --bind /dev/null "${CCWS_SYSROOT}/etc/ld.so.preload" || true

assert_CCWS_SYSROOT_must_be_mounted:
	test -d "${CCWS_SYSROOT}/dev"

private_cross_build: assert_CCWS_SYSROOT_must_be_mounted
	${MAKE} private_build

cross_mount:
	# implementation is profile specific
	${MAKE} bp_${BUILD_PROFILE}_mount

cross_umount:
	# should not fail, may be called on unmounted root
	sudo bash -c "${SETUP_SCRIPT}; umount --recursive \"\$${CCWS_SYSROOT}\" || true"

cross_common_install_build:
	sudo ${APT_INSTALL} qemu-user qemu-user-static binfmt-support
	sudo service binfmt-support restart

# ubuntu 18.04
cross_jetson_install_build_bionic:
	sudo apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/7fa2af80.pub
	${MAKE} download FILES="https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/cuda-repo-ubuntu1804_10.2.89-1_amd64.deb"
	sudo dpkg -i ${WORKSPACE_DIR}/cache/cuda-repo-ubuntu1804_10.2.89-1_amd64.deb
	sudo apt update
	sudo ${APT_INSTALL} g++-8-aarch64-linux-gnu cuda-nvcc-10-2

cross_jetson_install_host_bionic:
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
