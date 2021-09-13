# this script automatically sources profile specific setup script
DEB_SETUP_SCRIPT=${SETUP_SCRIPT} ${BASE_BUILD_PROFILE}

deb_%:
	${MAKE} wswraptarget TARGET="private_$@" SETUP_SCRIPT="${DEB_SETUP_SCRIPT}"

private_deb_compile:
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

private_deb_pack: assert_PKG_arg_must_be_specified private_dep_resolve private_deb_info assert_AUTHOR_must_not_be_empty assert_EMAIL_must_not_be_empty
	mkdir -p "${CCWS_INSTALL_DIR_BUILD_ROOT}/DEBIAN"
	mkdir -p "${CCWS_ARTIFACTS_DIR}"
	chmod -R g-w "${CCWS_INSTALL_DIR_BUILD_ROOT}/"
	find "${CCWS_INSTALL_DIR_BUILD_ROOT}/" -iname '*.pyc' -or -iname '__pycache__' | xargs --no-run-if-empty rm -Rf
	${CCWS_BUILD_PROFILE_DIR}/bin/control.sh
	${CCWS_BUILD_PROFILE_DIR}/bin/preinst.sh
	${CCWS_BUILD_PROFILE_DIR}/bin/postinst.sh
	rm -f "${CCWS_ARTIFACTS_DIR}/${CCWS_PKG_FULL_NAME}.deb"
	dpkg-deb --root-owner-group --build "${CCWS_INSTALL_DIR_BUILD_ROOT}" "${CCWS_ARTIFACTS_DIR}/${CCWS_PKG_FULL_NAME}.deb"

private_deb_version_hash: assert_PKG_arg_must_be_specified
	mkdir -p ${WORKSPACE_DIR}/build/version_hash
	${MAKE} --quiet private_info_with_deps \
		| grep path | sed 's/path: //' | sort \
		| xargs -I {} /bin/sh -c 'cd {}; echo {}; git show -s --format=%h; git diff' > ${WORKSPACE_DIR}/build/version_hash/${PKG}.all
	git show -s --format=%h >> ${WORKSPACE_DIR}/build/version_hash/${PKG}.all
	cat "${WORKSPACE_DIR}/build/version_hash/${PKG}.all" | md5sum | grep -o "^......" > ${WORKSPACE_DIR}/build/version_hash/${PKG}

private_deb_lint: assert_PKG_arg_must_be_specified
	lintian --pedantic --suppress-tags-from-file ${CCWS_BUILD_PROFILE_DIR}/lintian.supp "${CCWS_ARTIFACTS_DIR}/${CCWS_PKG_FULL_NAME}.deb"

deb_build: assert_BASE_BUILD_PROFILE_must_exist
	${MAKE} deb_compile
	${MAKE} deb_pack

bp_deb_install_build: bp_common_install_build
	sudo ${APT_INSTALL} dpkg lintian

