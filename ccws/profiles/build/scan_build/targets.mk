bp_scan_build_install_build: install_ccws_deps install_ccws_build_deps
	bash -c "${SETUP_SCRIPT}; sudo ${APT_INSTALL} clang-format-\$${CCWS_LLVM_VERSION} clang-tools-\$${CCWS_LLVM_VERSION} clang-tidy-\$${CCWS_LLVM_VERSION}"

