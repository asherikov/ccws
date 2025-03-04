deb_%:
	${MAKE} wswraptarget TARGET="private_$@"

private_deb_compile:
	echo ${CCWS_EXTRA_INSTALL_DIRS} | sed -e "s/ /\n/g" | xargs -I {} mkdir -p ${CCWS_INSTALL_DIR_BUILD_ROOT}/{}
	mkdir -p "${CCWS_DEBIAN_POSTINST_DIR}" "${CCWS_DEBIAN_PREINST_DIR}" "${CCWS_DEBIAN_POSTRM_DIR}" "${CCWS_DEBIAN_PRERM_DIR}"
	# trim first profile (must be deb) and proceed with the rest
	${MAKE} bp_${CCWS_SECONDARY_BUILD_PROFILE}_build CCWS_BUILD_PROFILES=${CCWS_BUILD_PROFILES_TAIL}
	echo "#!/bin/bash -x"                                                           >  "${CCWS_SOURCE_SCRIPT}"
	echo "CCWS_EXTRA_SOURCE_SCRIPTS=\"${CCWS_EXTRA_SOURCE_SCRIPTS}\""               >> "${CCWS_SOURCE_SCRIPT}"
	cat "${EXEC_PROFILES_DIR}/common/setup.bash" | grep -v "^#!"                    >> "${CCWS_SOURCE_SCRIPT}"
	test "${EXEC_PROFILE}" = "" || echo "${EXEC_PROFILE}" \
		| sed -e "s/^ *//"  -e "s/ *$$//"  -e "s/ \+/ /g"  -e "s/ /\\n/g" \
		| xargs --no-run-if-empty -I {} cat "${EXEC_PROFILES_DIR}/{}/setup.bash" | grep -v "^#!" >> "${CCWS_SOURCE_SCRIPT}"
	test ! -f "${EXEC_PROFILES_DIR}/vendor/setup.bash" || cat "${EXEC_PROFILES_DIR}/vendor/setup.bash" | grep -v "^#!" >> "${CCWS_SOURCE_SCRIPT}"

private_deb_info: assert_PKG_arg_must_be_specified private_deb_version_hash
	mkdir -p "${CCWS_DEB_INFO_DIR}"
	${MAKE} wsstatus > "${CCWS_DEB_INFO_DIR}/workspace_status.txt"
	echo "${PKG}" > "${CCWS_DEB_INFO_DIR}/pkg.txt"
	echo ${CCWS_BUILD_USER} ${CCWS_BUILD_TIME} > "${CCWS_DEB_INFO_DIR}/build_info.txt"
	cat ${WORKSPACE_DIR}/build/version_hash/${PKG_ID} \
		| sed -e 's/^/${CCWS_BUILD_TIME}_${ROS_DISTRO}_/' > "${CCWS_DEB_INFO_DIR}/version_hash.txt"
	echo "${VERSION}" > "${CCWS_DEB_INFO_DIR}/version.txt"

private_deb_pack: assert_PKG_arg_must_be_specified private_dep_resolve private_deb_info assert_AUTHOR_must_not_be_empty assert_EMAIL_must_not_be_empty
	# generate scripts
	mkdir -p "${CCWS_DEBIAN_DIR}"
	find "${CCWS_PRIMARY_BUILD_PROFILE_DIR}/bin/" -iname "*.sh" | xargs -I {} bash {}
	rm -Rf "${CCWS_DEBIAN_POSTINST_DIR}" "${CCWS_DEBIAN_PREINST_DIR}" "${CCWS_DEBIAN_POSTRM_DIR}" "${CCWS_DEBIAN_PRERM_DIR}"
	# cleanup
	find "${CCWS_INSTALL_DIR_BUILD_ROOT}/" -iname '*.pyc' -or -iname '__pycache__' | xargs --no-run-if-empty rm -Rf
	chmod -R g-w "${CCWS_INSTALL_DIR_BUILD_ROOT}/"
	# generate package
	mkdir -p "${CCWS_ARTIFACTS_DIR}"
	rm -f "${CCWS_ARTIFACTS_DIR}/${CCWS_PKG_FULL_NAME}.deb"
	${MAKE} private_dpkg_deb_${OS_DISTRO_BUILD}

private_dpkg_deb_bionic:
	dpkg-deb --root-owner-group --build "${CCWS_INSTALL_DIR_BUILD_ROOT}" "${CCWS_ARTIFACTS_DIR}/${CCWS_PKG_FULL_NAME}.deb"

private_dpkg_deb_focal: private_dpkg_deb_bionic
	#

private_dpkg_deb_jammy:
	dpkg-deb -Zzstd -z9 --root-owner-group --build "${CCWS_INSTALL_DIR_BUILD_ROOT}" "${CCWS_ARTIFACTS_DIR}/${CCWS_PKG_FULL_NAME}.deb"

private_dpkg_deb_noble:
	dpkg-deb -Zzstd -z9 --root-owner-group --threads-max=${JOBS} --build "${CCWS_INSTALL_DIR_BUILD_ROOT}" "${CCWS_ARTIFACTS_DIR}/${CCWS_PKG_FULL_NAME}.deb"


private_deb_version_hash: assert_PKG_arg_must_be_specified
	mkdir -p ${WORKSPACE_DIR}/build/version_hash
	${MAKE_QUIET} private_info_with_deps \
		| grep "^path:" | sed 's/path: //' | sort \
		| xargs -I {} /bin/sh -c 'cd {}; echo {}; git show -s --format=%h; git diff' > ${WORKSPACE_DIR}/build/version_hash/${PKG_ID}.all
	test ! -d .git || git show -s --format=%h >> ${WORKSPACE_DIR}/build/version_hash/${PKG_ID}.all
	cat "${WORKSPACE_DIR}/build/version_hash/${PKG_ID}.all" | md5sum | grep -o "^......" > ${WORKSPACE_DIR}/build/version_hash/${PKG_ID}

private_deb_lint: assert_PKG_arg_must_be_specified
	test -f "${CCWS_ARTIFACTS_DIR}/${CCWS_PKG_FULL_NAME}.deb"
	lintian --pedantic --suppress-tags-from-file ${CCWS_PRIMARY_BUILD_PROFILE_DIR}/lintian_${OS_DISTRO_BUILD}.supp "${CCWS_ARTIFACTS_DIR}/${CCWS_PKG_FULL_NAME}.deb"

bp_deb_build: assert_BUILD_PROFILES_must_exist
	${MAKE} private_deb_compile
	${MAKE} private_deb_pack

bp_deb_install_build: bp_common_install_build
	sudo ${APT_INSTALL} dpkg lintian

