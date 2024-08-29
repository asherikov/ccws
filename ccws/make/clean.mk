# Clean workspace
wsclean:
	rm -Rf "${WORKSPACE_DIR}"/build*
	rm -Rf "${WORKSPACE_DIR}"/devel*
	rm -Rf "${WORKSPACE_DIR}"/install*
	rm -Rf "${WORKSPACE_DIR}"/log*
	rm -Rf "${WORKSPACE_SRC}/.rosinstall.bak"

artifacts_clean:
	find "${WORKSPACE_DIR}/artifacts" -maxdepth 1 -mindepth 1 -not -name "\.gitignore" | xargs rm -Rf

# Purge workspace
wspurge: wsclean artifacts_clean
	rm -Rf "${WORKSPACE_SRC}"
	rm -Rf "${BUILD_PROFILES_DIR}/*/rosdep"

cache_clean:
	find ${CCWS_CACHE} -maxdepth 1 -mindepth 1 -not -name "\.gitignore" | xargs rm -Rf

cmake_cfg_clean:
	${MAKE} wswraptarget TARGET=cmake_cfg_clean

private_cmake_cfg_clean:
	rm -f ${CCWS_BUILD_DIR}/*/CMakeCache.txt

bp_purge:
	${MAKE} wswraptarget TARGET=bp_${BUILD_PROFILE}_purge

bp_%_purge: assert_BUILD_PROFILE_must_exist
	# placeholder target

bp_clean:
	${MAKE} wswraptarget TARGET=bp_${BUILD_PROFILE}_clean

bp_%_clean: assert_BUILD_PROFILE_must_exist
	rm -Rf "${WORKSPACE_DIR}/build/${BUILD_PROFILE}"
	rm -Rf "${WORKSPACE_DIR}/install/${BUILD_PROFILE}"
