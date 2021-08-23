# this script automatically sources PROFILE specific setup script
DEB_SETUP_SCRIPT=source ${WORKSPACE_DIR}/profiles/common/deb.bash

version_hash: assert_PKG_arg_must_be_specified
	mkdir -p ${WORKSPACE_DIR}/build/version_hash
	${MAKE} --quiet info_with_deps \
		| grep path | sed 's/path: //' | sort \
		| xargs -I {} /bin/sh -c 'cd {}; echo {}; git show -s --format=%h; git diff' > ${WORKSPACE_DIR}/build/version_hash/${PKG}.all
	git show -s --format=%h >> ${WORKSPACE_DIR}/build/version_hash/${PKG}.all
	cat "${WORKSPACE_DIR}/build/version_hash/${PKG}.all" | md5sum | grep -o "^......" > ${WORKSPACE_DIR}/build/version_hash/${PKG}

deb_%:
	${MAKE} wswraptarget TARGET="private_$@" SETUP_SCRIPT="${DEB_SETUP_SCRIPT}"

private_deb_build:
	${MAKE} private_build

private_deb_info: assert_PKG_arg_must_be_specified version_hash
	mkdir -p "${CCWS_DEB_INFO_DIR}"
	${MAKE} wsstatus > "${CCWS_DEB_INFO_DIR}/workspace_status.txt"
	echo "${PKG}" > "${CCWS_DEB_INFO_DIR}/pkg.txt"
	echo ${CCWS_BUILD_USER} ${CCWS_BUILD_TIME} > "${CCWS_DEB_INFO_DIR}/build_info.txt"
	cat ${WORKSPACE_DIR}/build/version_hash/${PKG} \
		| sed -e 's/^/${CCWS_BUILD_TIME}_${ROS_DISTRO}_/' > "${CCWS_DEB_INFO_DIR}/version.txt"

private_deb_pack: assert_PKG_arg_must_be_specified private_dep_resolve private_deb_info
	mkdir -p "${CCWS_INSTALL_DIR_BUILD_ROOT}/DEBIAN"
	chmod -R g-w "${CCWS_INSTALL_DIR_BUILD_ROOT}/"
	find "${CCWS_INSTALL_DIR_BUILD_ROOT}/" -iname '*.pyc' | xargs --no-run-if-empty rm
	${WORKSPACE_DIR}/scripts/deb/control.sh
	${WORKSPACE_DIR}/scripts/deb/preinst.sh
	${WORKSPACE_DIR}/scripts/deb/postinst.sh
	dpkg-deb --root-owner-group --build "${CCWS_INSTALL_DIR_BUILD_ROOT}" "install/${CCWS_PKG_FULL_NAME}.deb"

# see https://lintian.debian.org/tags/
private_deb_lint: assert_PKG_arg_must_be_specified
	lintian "install/${CCWS_PKG_FULL_NAME}.deb"

deb:
	${MAKE} wswraptarget TARGET="private_deb_build" SETUP_SCRIPT="${DEB_SETUP_SCRIPT}"
	${MAKE} wswraptarget TARGET="private_deb_pack" SETUP_SCRIPT="${DEB_SETUP_SCRIPT}"
