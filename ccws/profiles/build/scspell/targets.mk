bp_scspell_install_build:
	${PIPX_INSTALL} scspell3k

bp_scspell_build:
	bash -c "${SETUP_SCRIPT}; \
		find '${CCWS_SOURCE_DIR}/${DIR}' -iname '*.h' -or -iname '*.cpp' -or -iname '*.hpp' \
        | ${CCWS_XARGS} -P '${JOBS}' scspell --use-builtin-base-dict --override-dictionary \
		\"\$${CCWS_PRIMARY_BUILD_PROFILE_DIR}/dictionary\" {}"

scspell_interactive:
	bash -c "${SETUP_SCRIPT}; \
		find '${CCWS_SOURCE_DIR}/${DIR}' -iname '*.h' -or -iname '*.cpp' -or -iname '*.hpp' \
        | ${CCWS_XARGS} -o scspell --use-builtin-base-dict --override-dictionary \
		\"\$${CCWS_PRIMARY_BUILD_PROFILE_DIR}/dictionary\" {}"
