# converts absolute symlinks to relative in a mounted sysroot
# this is not needed with proot, but is necessary for some other approaches to
# cross compilation
cross_sysroot_fix_abs_symlinks:
	bash -c "${SETUP_SCRIPT}; \
		cd \"\$${CCWS_SYSROOT}\"; \
		find ./usr -lname '/*' -printf 'sudo ln --relative --symbolic --force ./%l %p\n' | /bin/sh"

cross_dep_install: deplist
	bash -c "${SETUP_SCRIPT}; \
		proot \
			\$${CCWS_PROOT_ARGS} \
			--cwd=\"\$${CCWS_WORKSPACE_DIR}\" \
			\"\$${CCWS_HOST_ROOT}/usr/bin/python\" \
			\"\$${CCWS_HOST_ROOT}/usr/bin/rosdep\" resolve $$(cat ${WORKSPACE_DIR}/build/deplist/${PKG} | paste -s -d ' ')" \
		| grep -v "^#" | sed 's/ /\n/g' > "${WORKSPACE_DIR}/build/deplist/${PKG}.apt"
	sudo bash -c "${SETUP_SCRIPT}; \
		cat '${WORKSPACE_DIR}/build/deplist/${PKG}.apt' \
		| xargs chroot \"\$${CCWS_SYSROOT}\" ${APT_INSTALL}"
