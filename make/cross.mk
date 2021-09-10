CROSS_SETUP_LOOP_DEV=sudo losetup -PL --find --show \"\$${CCWS_BUILD_PROFILE_DIR}/system.img\"

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
	mount "${DEVICE}" "${CCWS_SYSROOT}"
	mount --bind /etc/resolv.conf "${CCWS_SYSROOT}/etc/resolv.conf"
	mount --bind /dev "${CCWS_SYSROOT}/dev"
	mount --bind /dev/null "${CCWS_SYSROOT}/etc/ld.so.preload" || true

cross_mount:
	# may be different depending on profile
	${MAKE} ${BUILD_PROFILE}_mount

cross_umount:
	# should not fail, may be called on unmounted root
	sudo bash -c "${SETUP_SCRIPT}; umount --recursive \"\$${CCWS_SYSROOT}\" || true"

cross_common_install_build:
	sudo ${APT_INSTALL} qemu-user qemu-user-static
	sudo service binfmt-support restart
