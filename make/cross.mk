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
	#losetup -j "${CCWS_BUILD_PROFILE_DIR}/system.img" | cut -f 1 -d ':' | xargs --no-run-if-empty -I {} sudo losetup -d {}
	sudo losetup -PL --find --show "${CCWS_BUILD_PROFILE_DIR}/system.img" \
		| xargs -I {} sudo /bin/sh -c 'make private_cross_loopback_initialize LOOPBACK_DEVICE={} && mount ${SYSROOT_MOUNT_OPTIONS} "{}${SYSROOT_PARTITION}" "${CCWS_SYSROOT}"'
	# resolv.conf can be a symlink to a nonexistent systemd file or an absolute
	# symlink, in such cases we have to recreate this file in order to use bind
	# mounting
	# keep going if this hack fails
	test -L ${CCWS_SYSROOT}/etc/resolv.conf \
		&& sudo mv ${CCWS_SYSROOT}/etc/resolv.conf ${CCWS_SYSROOT}/etc/resolv.conf.back \
		&& sudo cp /etc/resolv.conf ${CCWS_SYSROOT}/etc/resolv.conf \
		|| true
	sudo mount --bind /etc/resolv.conf "${CCWS_SYSROOT}/etc/resolv.conf" || true
	sudo mount --bind /dev "${CCWS_SYSROOT}/dev"
	sudo mount --bind /tmp "${CCWS_SYSROOT}/tmp"
	# suppress noisy warnings
	sudo mount --bind /dev/null "${CCWS_SYSROOT}/etc/ld.so.preload" || true

# workaround for docker -- loopback device partitions not created in /dev
# https://github.com/moby/moby/issues/27886#issuecomment-417074845
private_cross_loopback_initialize:
	lsblk --raw --output MAJ:MIN --noheadings ${LOOPBACK_DEVICE} \
		| tail -n +2 | cat -n \
		| sed -e "s=\t= =" -e "s=:= =" -e "s= *\([0-9]\+\) *\([0-9]*\) *\([0-9]*\)=test -b ${LOOPBACK_DEVICE}p\1 || mknod ${LOOPBACK_DEVICE}p\1 b \2 \3=" \
		| /bin/sh

assert_CCWS_SYSROOT_must_be_mounted:
	mountpoint -q "${CCWS_SYSROOT}"

private_cross_build: assert_CCWS_SYSROOT_must_be_mounted
	# root must still be already mounted in order to determine ROS_DISTRO
	# remount in read only mode
	${MAKE} cross_umount
	${MAKE} cross_mount SYSROOT_MOUNT_OPTIONS="-o ro"
	# overlayfs has some issues with permissions, might need to use bindfs to remap user or libguestfs
	#mkdir -p ${CCWS_INSTALL_DIR_BUILD_ROOT}
	#mkdir -p ${CCWS_INSTALL_DIR_BUILD_ROOT}_overlayfs
	#sudo mount -t overlay overlay -o lowerdir="${CCWS_SYSROOT}",upperdir="${CCWS_INSTALL_DIR_BUILD_ROOT}",workdir="${CCWS_INSTALL_DIR_BUILD_ROOT}_overlayfs" "${CCWS_SYSROOT}"
	#sudo mount --bind /dev "${CCWS_SYSROOT}/dev"
	${MAKE} private_build

cross_mount:
	# implementation is profile specific
	${MAKE} bp_${BUILD_PROFILE}_mount

cross_umount:
	bash -c "${SETUP_SCRIPT}; ! mountpoint -q \"\$${CCWS_SYSROOT}\" || sudo umount --recursive \"\$${CCWS_SYSROOT}\""

# to be used in docker
cross_umount_all:
	sudo umount -a || true
	losetup | grep `pwd` | cut -f 1 -d " " | xargs --no-run-if-empty -I {} sudo losetup -d {}

cross_common_install_build:
	sudo ${APT_INSTALL} qemu-user qemu-user-static binfmt-support
	sudo service binfmt-support restart

# ubuntu 18.04
cross_jetson_install_build_bionic:
	sudo apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/7fa2af80.pub
	${MAKE} download FILES="https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/cuda-repo-ubuntu1804_10.2.89-1_amd64.deb"
	sudo dpkg -i ${CCWS_CACHE}/cuda-repo-ubuntu1804_10.2.89-1_amd64.deb
	sudo apt update
	sudo ${APT_INSTALL} g++-8-aarch64-linux-gnu cuda-nvcc-10-2 device-tree-compiler cpio

cross_flash:
	${MAKE} bp_${BUILD_PROFILE}_flash

bp_%_flash:
	test "${DEVICE}" != ""
	${MAKE} cross_umount
	bash -c "${SETUP_SCRIPT}; sudo dd if=\"\$${CCWS_BUILD_PROFILE_DIR}/system.img\" of=${DEVICE} status=progress bs=16M"

cross_get:
	${MAKE} bp_${BUILD_PROFILE}_get

cross_initialize:
	${MAKE} bp_${BUILD_PROFILE}_initialize

cross_install: cross_get
	${MAKE} cross_mount
	${MAKE} cross_initialize
	${MAKE} dep_install
	${MAKE} cross_umount

cross_pack:
	${MAKE} cross_umount
	${MAKE} wswraptarget TARGET=private_bp_${BUILD_PROFILE}_pack

cross_unpack:
	${MAKE} cross_umount
	${MAKE} wswraptarget TARGET=private_bp_${BUILD_PROFILE}_unpack

cross_purge:
	${MAKE} cross_umount
	${MAKE} wswraptarget TARGET=private_bp_${BUILD_PROFILE}_purge

private_cross_jetson_initialize_bionic:
	# 1. copy qemu in order to be able to do chroot
	# 2. 'wget -qO - https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | sudo chroot ./ apt-key add -;'
	#    may not work, using workaround from https://github.com/Microsoft/WSL/issues/3286
	# 3. NVIDIA overrides OpenCV package with version 4, but we need OpenCV 3 in melodic
	#    see `apt-cache policy libopencv-dev`
	sudo cp /usr/bin/qemu-aarch64-static ${CCWS_SYSROOT}/usr/bin/
	# might be necessary in some docker environments
	sudo update-binfmts --enable qemu-aarch64
	wget -qO - https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | gpg --dearmor | sudo chroot ${CCWS_SYSROOT} tee /etc/apt/trusted.gpg.d/ros.gpg > /dev/null
	echo 'deb http://packages.ros.org/ros/ubuntu bionic main' | sudo chroot ${CCWS_SYSROOT} tee /etc/apt/sources.list.d/ros-latest.list
	wget -qO - https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/7fa2af80.pub | gpg --dearmor | sudo chroot ${CCWS_SYSROOT} tee /etc/apt/trusted.gpg.d/nvidia-cuda.gpg > /dev/null
	# repos may be commented out
	sudo chroot ${CCWS_SYSROOT} sed -i 's/^# *deb/deb/' /etc/apt/sources.list.d/nvidia-l4t-apt-source.list
	#sudo chroot ${CCWS_SYSROOT} /bin/sh -c \
	#		'apt update; \
	#		apt upgrade --yes; \
	#		apt remove --yes libopencv-dev; \
	#		${APT_INSTALL} ca-certificates; \
	#		${APT_INSTALL} libopencv-dev:arm64=3.2.0+dfsg-4ubuntu0.1; \
	#		apt clean'
