bp_iwyu_build: assert_BUILD_PROFILES_must_exist assert_SECONDARY_BUILD_PROFILE_must_exist
	rm -Rf "${CCWS_BUILD_DIR}/"
	mkdir -p "${CCWS_BUILD_DIR}/"
	bash -c "${SETUP_SCRIPT}; \
		test -f '${CCWS_BUILD_DIR_BASE}/${CCWS_BUILD_PROFILES_LAST}/compile_commands.json'; \
		python3 '${CCWS_PRIMARY_BUILD_PROFILE_DIR}/ccws_filter_compile_commands.py' \
			'${CCWS_BUILD_DIR_BASE}/${CCWS_BUILD_PROFILES_LAST}/compile_commands.json' \
			'${CCWS_BUILD_DIR}/compile_commands.json' \
			\"\$${CCWS_STATIC_DIR_EXCEPTIONS}\""
	bash -c "${SETUP_SCRIPT}; \
		iwyu_tool \
			-p '${CCWS_BUILD_DIR}' \
			-j ${JOBS} \
			-- \$${CCWS_IWYU_ARGS} \
			> '${CCWS_BUILD_DIR}/iwyu.log' 2>&1"
	# include-what-you-use does not use exit codes to report findings, they
	# have to be detected in the log; the full log is saved to the file, only
	# suggested removals are shown on the screen; missing headers and errors
	# are not reported; findings for excluded paths are prevented by
	# filtering the compilation database; empty "should remove" sections of
	# files with additions only are discarded as well
	sed -n -e '/should remove these lines:/{:a;N;/\n$$/!ba;/\n- /p}' \
		'${CCWS_BUILD_DIR}/iwyu.log' > '${CCWS_BUILD_DIR}/iwyu.err'
	cat '${CCWS_BUILD_DIR}/iwyu.err'
	test ! -s '${CCWS_BUILD_DIR}/iwyu.err' || exit 1


bp_iwyu_install_build: install_ccws_deps
	sudo ${APT_INSTALL} iwyu
