# see profiles/build/common/cmake/ccws_conan_install.cmake
# not supported:
# 	packages are not very fresh and there are plenty of dependency conflicts
# 	conflict resolution is fragile and inconvenient https://docs.conan.io/2/tutorial/versioning/conflicts.html

# https://docs.conan.io/2/reference/environment.html#conan-home
export CCWS_CONAN_HOME?="${CCWS_CACHE}/conan/${CCWS_PRIMARY_BUILD_PROFILE}"

install_conan: install_python3
	${PIP3_INSTALL} conan

conan_list:
	bash -c "${SETUP_SCRIPT}; export CONAN_HOME=${CCWS_CONAN_HOME}; conan list --cache '*'"

conan_remove:
	bash -c "${SETUP_SCRIPT}; export CONAN_HOME=${CCWS_CONAN_HOME}; conan remove --confirm ${PKG}"

conan_purge:
	bash -c "${SETUP_SCRIPT}; rm -Rf ${CCWS_CONAN_HOME}"

