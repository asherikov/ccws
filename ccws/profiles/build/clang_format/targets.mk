bp_clang_format_install_build:
	bash -c "${SETUP_SCRIPT}; sudo ${APT_INSTALL} clang-format-\$${CCWS_LLVM_VERSION}"

bp_clang_format_build:
	bash -c "${SETUP_SCRIPT}; \
		find '${CCWS_SOURCE_DIR}/${DIR}' -iname '*.h' -or -iname '*.cpp' -or -iname '*.hpp' \
		| ${CCWS_XARGS} -P '${JOBS}' clang-format-\$${CCWS_LLVM_VERSION} --style='file:${CCWS_ROOT}/.clang-format' -i {}"
