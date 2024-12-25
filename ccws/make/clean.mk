# Clean workspace
wsclean:
	rm -rf "${WORKSPACE_DIR}"/build*
	rm -rf "${WORKSPACE_DIR}"/install*
	rm -rf "${WORKSPACE_DIR}"/log*
	rm -rf "${WORKSPACE_SRC}/.rosinstall.bak"

artifacts_clean:
	rm -rf "${WORKSPACE_DIR}/artifacts"

# Purge workspace
wspurge: wsclean artifacts_clean
	rm -rf "${WORKSPACE_SRC}"
	rm -rf "${BUILD_PROFILES_DIR}/*/rosdep"

cache_clean:
	find ${CCWS_CACHE} -maxdepth 1 -mindepth 1 -not -name "\.gitignore" | xargs rm -rf

cmake_cfg_clean:
	${MAKE} wswraptarget TARGET=cmake_cfg_clean

private_cmake_cfg_clean:
	rm -f ${CCWS_BUILD_SPACE_DIR}/*/CMakeCache.txt

bp_purge:
	echo "${CCWS_BUILD_PROFILES}" | sed -e 's/,/\n/g' | xargs -I {} ${MAKE} bp_{}_purge

bp_%_purge: assert_BUILD_PROFILES_must_exist
	# placeholder target

bp_clean:
	rm -rf "${CCWS_BUILD_SPACE_DIR}"
	rm -rf "${WORKSPACE_DIR}/install/${CCWS_BUILD_PROFILES_ID}"
	echo "${CCWS_BUILD_PROFILES}" | sed -e 's/,/\n/g' | xargs -I {} ${MAKE} bp_{}_clean

bp_%_clean: assert_BUILD_PROFILES_must_exist
	# placeholder target
