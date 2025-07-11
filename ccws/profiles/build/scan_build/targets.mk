bp_scan_build_install_build: install_ccws_deps
	bash -c "${SETUP_SCRIPT}; sudo ${APT_INSTALL} clang-tools-\$${CCWS_LLVM_VERSION} clang-tidy-\$${CCWS_LLVM_VERSION}"

