# subpackage generation parameters are set in setup.bash ('ON' or 'OFF')
CCWS_DEB_SUBPACKAGE_DIR=${CCWS_INSTALL_DIR}/${CCWS_PKG_FULL_NAME}-${CCWS_DEB_SUBPACKAGE}


deb_%:
	${MAKE} wswraptarget TARGET="private_$@"

private_deb_compile:
	# clean install directories in order to avoid packing of previously installed stuff
	rm -rf "${CCWS_INSTALL_DIR_BUILD_ROOT}"/*
	echo ${CCWS_EXTRA_INSTALL_DIRS} | sed -e "s/ /\n/g" | xargs -I {} mkdir -p ${CCWS_INSTALL_DIR_BUILD_ROOT}/{}
	mkdir -p "${CCWS_DEBIAN_POSTINST_DIR}" "${CCWS_DEBIAN_PREINST_DIR}" "${CCWS_DEBIAN_POSTRM_DIR}" "${CCWS_DEBIAN_PRERM_DIR}"
	# trim first profile (must be deb) and proceed with the rest
	${MAKE} bp_${CCWS_SECONDARY_BUILD_PROFILE}_build CCWS_BUILD_PROFILES=${CCWS_BUILD_PROFILES_TAIL}
	echo "CCWS_EXTRA_SOURCE_SCRIPTS=\"${CCWS_EXTRA_SOURCE_SCRIPTS}\""               > "${CCWS_SOURCE_SCRIPT}"
	echo "CCWS_PACKAGE_VERSION=\"${VERSION}:\$${CCWS_PACKAGE_VERSION}\""            >> "${CCWS_SOURCE_SCRIPT}"
	cat "${EXEC_PROFILES_DIR}/common/setup.bash" | grep -v "^#!"                    >> "${CCWS_SOURCE_SCRIPT}"
	test "${EXEC_PROFILE}" = "" || echo "${EXEC_PROFILE}" \
		| sed -e "s/^ *//"  -e "s/ *$$//"  -e "s/ \+/ /g"  -e "s/ /\\n/g" \
		| xargs --no-run-if-empty -I {} cat "${EXEC_PROFILES_DIR}/{}/setup.bash" | grep -v "^#!" >> "${CCWS_SOURCE_SCRIPT}"

private_deb_cleanup:
	# fix setup scripts
	find "${CCWS_INSTALL_DIR_BUILD}/share" -name 'package.sh' | xargs --no-run-if-empty -I {} sed -i "s=${CCWS_INSTALL_DIR_BUILD_ROOT}==g" {}
	sed -i "s=${CCWS_INSTALL_DIR_BUILD_ROOT}==g" "${CCWS_INSTALL_DIR_BUILD}"/setup.*
	sed -i "s=${CCWS_INSTALL_DIR_BUILD_ROOT}==g" "${CCWS_INSTALL_DIR_BUILD}"/local_setup.*
	# fix ament_index paths
	-sed -i "s=${CCWS_INSTALL_DIR_BUILD_ROOT}==g" "${CCWS_INSTALL_DIR_BUILD}/share/ament_index/resource_index/parent_prefix_path"/*
	# remove python cache files
	find "${CCWS_INSTALL_DIR_BUILD_ROOT}/" -iname '*.pyc' -or -iname '__pycache__' | xargs --no-run-if-empty rm -Rf
	# tweak permissions
	chmod -R g-w "${CCWS_INSTALL_DIR_BUILD_ROOT}/"

private_deb_info: assert_PKG_arg_must_be_specified private_deb_version_hash
	mkdir -p "${CCWS_DEB_INFO_DIR}"
	-${MAKE} wsstatus > "${CCWS_DEB_INFO_DIR}/workspace_status.txt"
	echo "${PKG}" > "${CCWS_DEB_INFO_DIR}/pkg.txt"
	echo ${CCWS_BUILD_USER} ${CCWS_BUILD_TIME} > "${CCWS_DEB_INFO_DIR}/build_info.txt"
	cat ${CCWS_BUILD_DIR}/.ccws/version_hash/${PKG_ID} \
		| sed -e 's/^/${CCWS_BUILD_TIME}_${ROS_DISTRO}_/' > "${CCWS_DEB_INFO_DIR}/version_hash.txt"
	echo "${VERSION}" > "${CCWS_DEB_INFO_DIR}/version.txt"

private_deb_split_subpackages_OFF:
	#

private_deb_split_subpackages_ON:
	${MAKE} private_deb_split_subpackage CCWS_DEB_SUBPACKAGE=dev
	${MAKE} private_deb_split_subpackage CCWS_DEB_SUBPACKAGE=dbg
	${MAKE} private_deb_split_subpackage CCWS_DEB_SUBPACKAGE=doc

private_deb_split_subpackage:
	ccws_deb_split.sh ${CCWS_DEB_SUBPACKAGE} "${CCWS_INSTALL_DIR_BUILD_ROOT}" "${CCWS_DEB_SUBPACKAGE_DIR}" "${CCWS_TRIPLE}"

private_deb_pack: assert_PKG_arg_must_be_specified private_dep_resolve private_deb_info assert_AUTHOR_must_not_be_empty assert_EMAIL_must_not_be_empty
	# generate scripts
	mkdir -p "${CCWS_DEBIAN_DIR}"
	find "${CCWS_PRIMARY_BUILD_PROFILE_DIR}/bin/" -iname "*.sh" | xargs -I {} bash {}
	rm -Rf "${CCWS_DEBIAN_POSTINST_DIR}" "${CCWS_DEBIAN_PREINST_DIR}" "${CCWS_DEBIAN_POSTRM_DIR}" "${CCWS_DEBIAN_PRERM_DIR}"
	# generate package
	mkdir -p "${CCWS_ARTIFACTS_DIR}"
	rm -f "${CCWS_ARTIFACTS_DIR}/${CCWS_PKG_FULL_NAME}.deb"
	${MAKE} private_dpkg_deb_${OS_DISTRO_BUILD}
	${MAKE} private_deb_pack_subpackages_${CCWS_DEB_SUBPACKAGES}

private_deb_pack_subpackages_OFF:
	#

private_deb_pack_subpackages_ON:
	# build dependencies are resolved for the 'dev' package
	${MAKE} private_dep_resolve CCWS_DEP_TYPE=build DEPLIST_FILE=${DEPLIST_FILE_DEV_DEPS}
	${MAKE} private_deb_pack_subpackage CCWS_DEB_SUBPACKAGE=dev
	${MAKE} private_deb_pack_subpackage CCWS_DEB_SUBPACKAGE=dbg
	${MAKE} private_deb_pack_subpackage CCWS_DEB_SUBPACKAGE=doc

# 'private_deb_info' is not repeated here: subpackages are packed only after
# the main package, which generates the shared metadata
private_deb_pack_subpackage: assert_PKG_arg_must_be_specified assert_AUTHOR_must_not_be_empty assert_EMAIL_must_not_be_empty
	# subpackages without files are skipped; dependencies: 'dev' -- main
	# package and its build dependencies, 'dbg' -- main package, 'doc' -- none
	if [ -n "$$(find "${CCWS_DEB_SUBPACKAGE_DIR}" -type f -not -path "${CCWS_DEB_SUBPACKAGE_DIR}/DEBIAN/*" -print -quit)" ]; then \
		mkdir -p "${CCWS_DEB_SUBPACKAGE_DIR}/DEBIAN" ; \
		SUBPACKAGE_DEPENDS="" ; \
		test "${CCWS_DEB_SUBPACKAGE}" = doc || \
			SUBPACKAGE_DEPENDS="$$(echo "${CCWS_PKG_FULL_NAME}" | sed 's/_/-/g') (= $$(sed 's/_/-/g' "${CCWS_DEB_INFO_DIR}/version_hash.txt"))" ; \
		test "${CCWS_DEB_SUBPACKAGE}" != dev || { \
			test ! -s "${DEPLIST_FILE_DEV_DEPS}.deb" || \
				SUBPACKAGE_DEPENDS="$${SUBPACKAGE_DEPENDS}, $$(paste -s -d ',' < "${DEPLIST_FILE_DEV_DEPS}.deb" | sed -e 's/,/, /g')" ; \
		} ; \
		env CCWS_DEBIAN_DIR="${CCWS_DEB_SUBPACKAGE_DIR}/DEBIAN" \
			CCWS_DEB_PKG_NAME="${CCWS_PKG_FULL_NAME}-${CCWS_DEB_SUBPACKAGE}" \
			CCWS_DEB_PKG_DIR="${CCWS_DEB_SUBPACKAGE_DIR}" \
			CCWS_DEB_PKG_ARCH="${CCWS_DEB_SUBPACKAGE_ARCH_${CCWS_DEB_SUBPACKAGE}}" \
			CCWS_DEB_PKG_DESCRIPTION="${VENDOR} ${PKG} (${CCWS_DEB_SUBPACKAGE_DESCRIPTION_${CCWS_DEB_SUBPACKAGE}})" \
			CCWS_DEB_PKG_DEPENDS="$${SUBPACKAGE_DEPENDS}" \
			bash "${CCWS_PRIMARY_BUILD_PROFILE_DIR}/bin/control.sh" ; \
		rm -f "${CCWS_ARTIFACTS_DIR}/${CCWS_PKG_FULL_NAME}-${CCWS_DEB_SUBPACKAGE}.deb" ; \
		${MAKE} private_dpkg_deb_${OS_DISTRO_BUILD} \
			CCWS_DEB_ROOT="${CCWS_DEB_SUBPACKAGE_DIR}" \
			CCWS_DEB_OUTPUT="${CCWS_ARTIFACTS_DIR}/${CCWS_PKG_FULL_NAME}-${CCWS_DEB_SUBPACKAGE}.deb" ; \
	else \
		echo "Skipping empty subpackage '${CCWS_DEB_SUBPACKAGE}'" ; \
	fi

private_dpkg_deb_bionic:
	dpkg-deb --root-owner-group --build "${CCWS_DEB_ROOT}" "${CCWS_DEB_OUTPUT}"

private_dpkg_deb_focal: private_dpkg_deb_bionic
	#

private_dpkg_deb_jammy:
	dpkg-deb -Zzstd -z9 --root-owner-group --build "${CCWS_DEB_ROOT}" "${CCWS_DEB_OUTPUT}"

private_dpkg_deb_noble:
	dpkg-deb -Zzstd -z9 --root-owner-group --threads-max=${JOBS} --build "${CCWS_DEB_ROOT}" "${CCWS_DEB_OUTPUT}"

private_dpkg_deb_resolute: private_dpkg_deb_noble
	# ubuntu 26

private_deb_version_hash: assert_PKG_arg_must_be_specified
	mkdir -p ${CCWS_BUILD_DIR}/.ccws/version_hash/
	${MAKE_QUIET} private_info_with_deps \
		| grep "^path:" | sed 's/path: //' | sort \
		| xargs -I {} /bin/sh -c 'cd {}; echo {}; git show -s --format=%h; git diff' > ${CCWS_BUILD_DIR}/.ccws/version_hash/${PKG_ID}.all
	test ! -d .git || git show -s --format=%h >> ${CCWS_BUILD_DIR}/.ccws/version_hash/${PKG_ID}.all
	cat "${CCWS_BUILD_DIR}/.ccws/version_hash/${PKG_ID}.all" | md5sum | grep -o "^......" > ${CCWS_BUILD_DIR}/.ccws/version_hash/${PKG_ID}

private_deb_lint: assert_PKG_arg_must_be_specified
	test -f "${CCWS_ARTIFACTS_DIR}/${CCWS_PKG_FULL_NAME}.deb"
	lintian --pedantic --suppress-tags-from-file ${CCWS_PRIMARY_BUILD_PROFILE_DIR}/lintian_${OS_DISTRO_BUILD}.supp "${CCWS_ARTIFACTS_DIR}/${CCWS_PKG_FULL_NAME}.deb"
	${MAKE} private_deb_lint_subpackages_${CCWS_DEB_SUBPACKAGES}

private_deb_lint_subpackages_OFF:
	#

private_deb_lint_subpackages_ON:
	test ! -f "${CCWS_ARTIFACTS_DIR}/${CCWS_PKG_FULL_NAME}-dev.deb" || \
		lintian --pedantic --suppress-tags-from-file ${CCWS_PRIMARY_BUILD_PROFILE_DIR}/lintian_${OS_DISTRO_BUILD}.supp "${CCWS_ARTIFACTS_DIR}/${CCWS_PKG_FULL_NAME}-dev.deb"
	test ! -f "${CCWS_ARTIFACTS_DIR}/${CCWS_PKG_FULL_NAME}-dbg.deb" || \
		lintian --pedantic --suppress-tags-from-file ${CCWS_PRIMARY_BUILD_PROFILE_DIR}/lintian_${OS_DISTRO_BUILD}.supp "${CCWS_ARTIFACTS_DIR}/${CCWS_PKG_FULL_NAME}-dbg.deb"
	test ! -f "${CCWS_ARTIFACTS_DIR}/${CCWS_PKG_FULL_NAME}-doc.deb" || \
		lintian --pedantic --suppress-tags-from-file ${CCWS_PRIMARY_BUILD_PROFILE_DIR}/lintian_${OS_DISTRO_BUILD}.supp "${CCWS_ARTIFACTS_DIR}/${CCWS_PKG_FULL_NAME}-doc.deb"

bp_deb_build: assert_BUILD_PROFILES_must_exist
	${MAKE} private_deb_compile
	${MAKE} private_deb_cleanup
	${MAKE} private_deb_split_subpackages_${CCWS_DEB_SUBPACKAGES}
	${MAKE} private_deb_pack CCWS_DEP_TYPE=${CCWS_DEB_DEP_TYPE}

bp_deb_install_build: install_ccws_deps
	sudo ${APT_INSTALL} dpkg lintian
