bp_clang_tidy_install_build: install_ccws_deps
	bash -c "${SETUP_SCRIPT}; sudo ${APT_INSTALL} clang-tidy-\$${CCWS_LLVM_VERSION} clang-\$${CCWS_LLVM_VERSION}"

