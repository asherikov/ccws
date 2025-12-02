# Clean workspace
wsclean:
	rm -rf "${CCWS_BUILD_DIR_BASE}"/*
	rm -rf "${CCWS_INSTALL_DIR_BASE}"/*
	rm -rf "${CCWS_SOURCE_DIR}/.rosinstall.bak"

artifacts_clean:
	rm -rf "${CCWS_ARTIFACTS_DIR_BASE}"/*

# Purge workspace
wspurge: wsclean artifacts_clean
	rm -rf "${CCWS_SOURCE_DIR}"
	test ! -d "${CCWS_SYSROOT_DIR_BASE}" || ${MAKE} purge_sysroot

purge_sysroot:
	sudo umount --recursive "${CCWS_SYSROOT_DIR_BASE}"
	sudo rm -rf "${CCWS_SYSROOT_DIR_BASE}"/*

cache_clean:
	find ${CCWS_CACHE} -maxdepth 1 -mindepth 1 -not -name "\.gitignore" | xargs rm -rf

cmake_cfg_clean:
	${MAKE} wswraptarget TARGET=cmake_cfg_clean

private_cmake_cfg_clean:
	rm -f ${CCWS_BUILD_DIR}/*/CMakeCache.txt

bp_purge:
	echo "${CCWS_BUILD_PROFILES}" | sed -e 's/,/\n/g' | ${CCWS_XARGS} ${MAKE} bp_{}_purge

bp_%_purge: assert_BUILD_PROFILES_must_exist
	# placeholder target

bp_clean:
	rm -rf "${CCWS_BUILD_DIR}"
	rm -rf "${CCWS_INSTALL_DIR}"
	echo "${CCWS_BUILD_PROFILES}" | sed -e 's/,/\n/g' | ${CCWS_XARGS} ${MAKE} bp_{}_clean

bp_%_clean: assert_BUILD_PROFILES_must_exist
	# placeholder target
