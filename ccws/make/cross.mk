export CCWS_CROSS_HOST_PYTHON?=NO

# converts absolute symlinks to relative in a mounted sysroot
# this is not needed with proot, but is necessary for some other approaches to
# cross compilation
cross_sysroot_fix_abs_symlinks:
	bash -c "${SETUP_SCRIPT}; \
		cd \"\$${CCWS_SYSROOT_MOUNTPOINT}\"; \
		find ./usr -lname '/*' -printf 'sudo ln --relative --symbolic --force ./%l %p\n' | /bin/sh"

# internal target, should be called with initialized environment
private_cross_mount_loopback:
	mkdir -p "${CCWS_SYSROOT_MOUNTPOINT}"
	#losetup -j "${CCWS_SYSROOT_DIR}/system.img" | cut -f 1 -d ':' | ${CCWS_XARGS} sudo losetup -d {}
	sudo losetup -PL --find --show "${CCWS_SYSROOT_DIR}/system.img" \
		| ${CCWS_XARGS} sudo /bin/sh -c 'make private_cross_loopback_initialize LOOPBACK_DEVICE={} && mount ${SYSROOT_MOUNT_OPTIONS} "{}${SYSROOT_PARTITION}" "${CCWS_SYSROOT_MOUNTPOINT}"'

# internal target, should be called with initialized environment
private_cross_mount_specialfs:
	test -n "${CCWS_SYSROOT_MOUNTPOINT}"
	# resolv.conf can be a symlink to a nonexistent systemd file or an absolute
	# symlink, in such cases we have to recreate this file in order to use bind
	# mounting
	# keep going if this hack fails
	test -L ${CCWS_SYSROOT_MOUNTPOINT}/etc/resolv.conf \
		&& sudo mv ${CCWS_SYSROOT_MOUNTPOINT}/etc/resolv.conf ${CCWS_SYSROOT_MOUNTPOINT}/etc/resolv.conf.back \
		&& sudo cp /etc/resolv.conf ${CCWS_SYSROOT_MOUNTPOINT}/etc/resolv.conf \
		|| true
	sudo mount --bind /etc/resolv.conf "${CCWS_SYSROOT_MOUNTPOINT}/etc/resolv.conf" || true
	sudo mount --bind /dev "${CCWS_SYSROOT_MOUNTPOINT}/dev"
	sudo mount --bind /tmp "${CCWS_SYSROOT_MOUNTPOINT}/tmp"
	sudo mount --bind /proc "${CCWS_SYSROOT_MOUNTPOINT}/proc"
	# suppress noisy warnings
	sudo mount --bind /dev/null "${CCWS_SYSROOT_MOUNTPOINT}/etc/ld.so.preload" || true

# workaround for docker -- loopback device partitions not created in /dev
# https://github.com/moby/moby/issues/27886#issuecomment-417074845
private_cross_loopback_initialize:
	lsblk --raw --output MAJ:MIN --noheadings ${LOOPBACK_DEVICE} \
		| tail -n +2 | cat -n \
		| sed -e "s=\t= =" -e "s=:= =" -e "s= *\([0-9]\+\) *\([0-9]*\) *\([0-9]*\)=test -b ${LOOPBACK_DEVICE}p\1 || mknod ${LOOPBACK_DEVICE}p\1 b \2 \3=" \
		| /bin/sh

assert_CCWS_SYSROOT_must_be_mounted:
	#mountpoint -q "${CCWS_SYSROOT_MOUNTPOINT}"
	test -d "${CCWS_SYSROOT_MOUNTPOINT}/etc"

private_cross_build: assert_CCWS_SYSROOT_must_be_mounted
	# root must still be already mounted in order to determine ROS_DISTRO
	# remount in read only mode
	${MAKE} cross_umount
	${MAKE} cross_mount SYSROOT_MOUNT_OPTIONS="-o ro"
	# overlayfs has some issues with permissions, might need to use bindfs to remap user or libguestfs
	#mkdir -p ${CCWS_INSTALL_DIR_BUILD_ROOT}
	#mkdir -p ${CCWS_INSTALL_DIR_BUILD_ROOT}_overlayfs
	#sudo mount -t overlay overlay -o lowerdir="${CCWS_SYSROOT_MOUNTPOINT}",upperdir="${CCWS_INSTALL_DIR_BUILD_ROOT}",workdir="${CCWS_INSTALL_DIR_BUILD_ROOT}_overlayfs" "${CCWS_SYSROOT_MOUNTPOINT}"
	#sudo mount --bind /dev "${CCWS_SYSROOT_MOUNTPOINT}/dev"
	${MAKE} private_build

cross_mount:
	# implementation is profile specific
	${MAKE} bp_${CCWS_PRIMARY_BUILD_PROFILE}_mount

cross_umount:
	bash -c "${SETUP_SCRIPT}; \
		test -n \"\$${CCWS_SYSROOT_MOUNTPOINT}\" \
		&& ((mountpoint -q \"\$${CCWS_SYSROOT_MOUNTPOINT}\" && sudo umount --recursive \"\$${CCWS_SYSROOT_MOUNTPOINT}\") \
		|| (mount | cut -f 3 -d ' ' | (grep \"\$${CCWS_SYSROOT_MOUNTPOINT}\" || true) | ${CCWS_XARGS} sudo umount {}))"

# to be used in docker
cross_umount_all:
	sudo umount -a || true
	losetup | grep `pwd` | cut -f 1 -d " " | ${CCWS_XARGS} sudo losetup -d {}

cross_common_install_build:
	sudo ${APT_INSTALL} qemu-user qemu-user-static binfmt-support
	sudo service binfmt-support restart
	bash -c "${SETUP_SCRIPT}; mkdir -p \"\$${CCWS_SYSROOT_DIR}\""

cross_flash:
	${MAKE} bp_${CCWS_PRIMARY_BUILD_PROFILE}_flash

bp_%_flash:
	test "${DEVICE}" != ""
	${MAKE} cross_umount
	bash -c "${SETUP_SCRIPT}; sudo dd if=\"\$${CCWS_SYSROOT_DIR}/system.img\" of=${DEVICE} status=progress bs=16M"

cross_get:
	${MAKE} bp_${CCWS_PRIMARY_BUILD_PROFILE}_get

cross_initialize:
	${MAKE} bp_${CCWS_PRIMARY_BUILD_PROFILE}_initialize

cross_install: cross_get
	${MAKE} cross_mount
	${MAKE} cross_initialize
	${MAKE} dep_install
	${MAKE} cross_umount

cross_pack:
	${MAKE} cross_umount
	${MAKE} wswraptarget TARGET=private_bp_${CCWS_PRIMARY_BUILD_PROFILE}_pack

cross_unpack:
	${MAKE} cross_umount
	${MAKE} wswraptarget TARGET=private_bp_${CCWS_PRIMARY_BUILD_PROFILE}_unpack

cross_purge:
	${MAKE} cross_umount
	${MAKE} wswraptarget TARGET=private_bp_${CCWS_PRIMARY_BUILD_PROFILE}_purge

cross_python_soabi: assert_CCWS_SYSROOT_must_be_mounted
	printf "from sysconfig import get_config_var\nprint(get_config_var('SOABI'))\n" \
		| bash -c "${SETUP_SCRIPT}; sudo chroot \"\$${CCWS_SYSROOT_MOUNTPOINT}\" python3"
