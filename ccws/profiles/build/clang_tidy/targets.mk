bp_clang_tidy_install_build: bp_common_install_build
	bash -c "${SETUP_SCRIPT}; sudo ${APT_INSTALL} clang-tidy-\$${CCWS_LLVM_VERSION}"

