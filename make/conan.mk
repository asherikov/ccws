# experimental conan support
# see profiles/build/common/cmake/ccws_conan_install.cmake
# using conan doesn't seem to be a good option: 
# 	packages are not very fresh and there are plenty of dependency conflicts

install_conan: install_python3
	${PIP3_INSTALL} conan

conan_list:
	bash -c "${SETUP_SCRIPT}; conan list --cache '*'"

conan_remove:
	bash -c "${SETUP_SCRIPT}; conan remove --confirm ${PKG}"

conan_purge:
	bash -c "${SETUP_SCRIPT}; rm -Rf \$${CONAN_HOME}"

