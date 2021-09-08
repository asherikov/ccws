# this script automatically sources profile specific setup script
DEB_SETUP_SCRIPT=${SETUP_SCRIPT} ${BASE_BUILD_PROFILE}

deb_%:
	${MAKE} wswraptarget TARGET="private_$@" SETUP_SCRIPT="${DEB_SETUP_SCRIPT}"

private_deb_build:
	${MAKE} private_build
	# TODO optionally copy other execution profiles
	cp -r "${EXEC_PROFILES_DIR}/common/setup.bash" "${CCWS_INSTALL_DIR_BUILD}/${VENDOR}_setup.bash"
	test ! -f "${EXEC_PROFILES_DIR}/vendor/setup.bash" || cat "${EXEC_PROFILES_DIR}/vendor/setup.bash" >> "${CCWS_INSTALL_DIR_BUILD}/${VENDOR}_setup.bash"

private_deb_info: assert_PKG_arg_must_be_specified private_deb_version_hash
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
	${CCWS_BUILD_PROFILE_DIR}/bin/control.sh
	${CCWS_BUILD_PROFILE_DIR}/bin/preinst.sh
	${CCWS_BUILD_PROFILE_DIR}/bin/postinst.sh
	dpkg-deb --root-owner-group --build "${CCWS_INSTALL_DIR_BUILD_ROOT}" "install/${CCWS_PKG_FULL_NAME}.deb"

private_deb_version_hash: assert_PKG_arg_must_be_specified
	mkdir -p ${WORKSPACE_DIR}/build/version_hash
	${MAKE} --quiet private_info_with_deps \
		| grep path | sed 's/path: //' | sort \
		| xargs -I {} /bin/sh -c 'cd {}; echo {}; git show -s --format=%h; git diff' > ${WORKSPACE_DIR}/build/version_hash/${PKG}.all
	git show -s --format=%h >> ${WORKSPACE_DIR}/build/version_hash/${PKG}.all
	cat "${WORKSPACE_DIR}/build/version_hash/${PKG}.all" | md5sum | grep -o "^......" > ${WORKSPACE_DIR}/build/version_hash/${PKG}

# see https://lintian.debian.org/tags/
private_deb_lint: assert_PKG_arg_must_be_specified
	lintian "install/${CCWS_PKG_FULL_NAME}.deb"

deb_build: assert_BASE_BUILD_PROFILE_must_exist
	${MAKE} wswraptarget TARGET="private_deb_build" SETUP_SCRIPT="${DEB_SETUP_SCRIPT}"
	${MAKE} wswraptarget TARGET="private_deb_pack" SETUP_SCRIPT="${DEB_SETUP_SCRIPT}"

