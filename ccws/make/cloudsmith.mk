cloudsmith_install: cloudsmith_install_${OS_DISTRO_BUILD}
	#

cloudsmith_install_jammy:
	python3 -m pip install cloudsmith-cli

cloudsmith_install_%:
	python3 -m pip install --break-system-packages cloudsmith-cli

cloudsmith_push_all:
	find "${CCWS_ARTIFACTS_DIR_BASE}" -iname *.deb \
		| ${CCWS_XARGS} cloudsmith push deb ${REPO} {}
