cloudsmith_install:
	${PIPX_INSTALL} cloudsmith-cli

cloudsmith_push_all:
	find "${CCWS_ARTIFACTS_DIR_BASE}" -iname *.deb \
		| ${CCWS_XARGS} cloudsmith push deb "${REPO}" {}
