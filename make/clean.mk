# Clean workspace
wsclean:
	find ${WORKSPACE_DIR}/artifacts -maxdepth 1 -mindepth 1 -not -name "\.gitignore" | xargs rm -Rf
	rm -Rf build*
	rm -Rf devel*
	rm -Rf install*
	rm -Rf log*
	rm -Rf src/.rosinstall.bak


# Purge workspace
wspurge: wsclean
	rm -Rf src
	rm -Rf "${BUILD_PROFILES_DIR}/*/rosdep"


wsclean_build:
	bash -c "${SETUP_SCRIPT}; rm -Rf \"\$${CCWS_BUILD_DIR}\""

purge: clean
	${MAKE} ${BUILD_PROFILE}_purge

%_purge: assert_BUILD_PROFILE_must_exist
	# placeholder target

clean:
	rm -Rf "build/${BUILD_PROFILE}"
	rm -Rf "install/${BUILD_PROFILE}"
