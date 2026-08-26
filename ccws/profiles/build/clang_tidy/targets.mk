bp_clang_tidy_install_build: bp_clang_install_build
	bash -c "${SETUP_SCRIPT}; sudo ${APT_INSTALL} clang-format-\$${CCWS_LLVM_VERSION} clang-tidy-\$${CCWS_LLVM_VERSION}"

