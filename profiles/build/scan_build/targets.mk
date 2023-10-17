bp_scan_build_install_build: bp_common_install_build
	bash -c "${SETUP_SCRIPT}; sudo ${APT_INSTALL} clang-tools-\$${CCWS_LLVM_VERSION} clang-tidy-\$${CCWS_LLVM_VERSION}"

