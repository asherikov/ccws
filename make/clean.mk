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


wsclean_build:
	bash -c "${SETUP_SCRIPT}; rm -Rf \"\$${CCWS_BUILD_DIR}\""

purge: clean
	${MAKE} ${PROFILE}_purge

%_purge:
	# placeholder target, dont call use manually
	test -d "${WORKSPACE_DIR}/profiles/$*"

clean:
	rm -Rf "build/${PROFILE}"
	rm -Rf "install/${PROFILE}"
