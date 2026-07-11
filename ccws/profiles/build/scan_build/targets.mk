bp_scan_build_install_build: install_ccws_deps install_ccws_build_deps
	bash -c "${SETUP_SCRIPT}; sudo ${APT_INSTALL} clang-tools-\$${CCWS_LLVM_VERSION} clang-tidy-\$${CCWS_LLVM_VERSION}"
	${MAKE} bp_scan_build_install_build_${OS_DISTRO_BUILD}

bp_scan_build_install_build_%:
	# nothing to do

bp_scan_build_install_build_resolute:
	# missing dependency?
	sudo ${APT_INSTALL} g++-16
