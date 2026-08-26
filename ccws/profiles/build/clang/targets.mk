bp_clang_install_build: install_ccws_deps
	bash -c "${SETUP_SCRIPT}; sudo ${APT_INSTALL} clang-\$${CCWS_LLVM_VERSION}"
