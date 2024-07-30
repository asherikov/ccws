# Clean workspace
wsclean:
	rm -Rf build*
	rm -Rf devel*
	rm -Rf install*
	rm -Rf log*
	rm -Rf "${WORKSPACE_SRC}/.rosinstall.bak"

artifacts_clean:
	find ${WORKSPACE_DIR}/artifacts -maxdepth 1 -mindepth 1 -not -name "\.gitignore" | xargs rm -Rf

# Purge workspace
wspurge: wsclean artifacts_clean
	rm -Rf "${WORKSPACE_SRC}"
	rm -Rf "${BUILD_PROFILES_DIR}/*/rosdep"

cache_clean:
	find ${CCWS_CACHE} -maxdepth 1 -mindepth 1 -not -name "\.gitignore" | xargs rm -Rf

bp_purge:
	${MAKE} wswraptarget TARGET=bp_${BUILD_PROFILE}_purge

bp_%_purge: assert_BUILD_PROFILE_must_exist
	# placeholder target

bp_clean:
	${MAKE} wswraptarget TARGET=bp_${BUILD_PROFILE}_clean

bp_%_clean: assert_BUILD_PROFILE_must_exist
	rm -Rf "build/${BUILD_PROFILE}"
	rm -Rf "install/${BUILD_PROFILE}"

