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
	sudo ${APT_INSTALL} qemu-user qemu-user-static
	sudo service binfmt-support restart
