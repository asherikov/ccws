CROSS_SETUP_LOOP_DEV=sudo losetup -PL --find --show \"\$${CCWS_PROFILE_DIR}/system.img\"

# converts absolute symlinks to relative in a mounted sysroot
# this is not needed with proot, but is necessary for some other approaches to
# cross compilation
cross_sysroot_fix_abs_symlinks:
	bash -c "${SETUP_SCRIPT}; \
		cd \"\$${CCWS_SYSROOT}\"; \
		find ./usr -lname '/*' -printf 'sudo ln --relative --symbolic --force ./%l %p\n' | /bin/sh"

cross_dep_install:
	${MAKE} cross_mount
	${MAKE} rosdep
	-sudo bash -c "${SETUP_SCRIPT}; \
		cat '${WORKSPACE_DIR}/build/deplist/${PKG}.deb' \
		| xargs chroot \"\$${CCWS_SYSROOT}\" ${APT_INSTALL}"
	${MAKE} cross_umount

# internal target, should be called with initialized environment
cross_sysroot_mount:
	mount "${DEVICE}" "$${CCWS_SYSROOT}"
	mount --bind /etc/resolv.conf "$${CCWS_SYSROOT}/etc/resolv.conf"
	mount --bind /dev "$${CCWS_SYSROOT}/dev"

cross_mount:
	# may be different depending on profile
	${MAKE} ${PROFILE}_mount

cross_umount:
	# should not fail, may be called on unmounted root
	sudo bash -c "${SETUP_SCRIPT}; umount --recursive \"\$${CCWS_SYSROOT}\" || true"

cross_install_common_host_deps:
	${APT_INSTALL} qemu-user-static

cross_fetch:
	${MAKE} ${PROFILE}_fetch

%_fetch:
	# placeholder target, dont call use manually
	test -d "${WORKSPACE_DIR}/profiles/$*"
