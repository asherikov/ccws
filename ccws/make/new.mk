new: assert_PKG_arg_must_be_specified
	mkdir -p "${WORKSPACE_SRC}"
	${MAKE} new_${OS_DISTRO_BUILD}
	mkdir -p "${WORKSPACE_SRC}/${PKG}/include/${PKG}"
	cd "${WORKSPACE_SRC}/${PKG}"; git init
	find "${WORKSPACE_SRC}/${PKG}" -type f | xargs sed -i "s/@@PACKAGE@@/${PKG}/g"
	find "${WORKSPACE_SRC}/${PKG}" -type f | xargs sed -i "s/@@AUTHOR@@/${AUTHOR}/g"
	find "${WORKSPACE_SRC}/${PKG}" -type f | xargs sed -i "s/@@EMAIL@@/${EMAIL}/g"
	find "${WORKSPACE_SRC}/${PKG}" -type f | xargs sed -i "s/@@LICENSE@@/${LICENSE}/g"

new_bionic: new_focal
	# passthrough

new_focal:
	cp -R ${CCWS_DIR}/examples/pkg_catkin "${WORKSPACE_SRC}/${PKG}"

new_jammy:
	cp -R ${CCWS_DIR}/examples/pkg_ament "${WORKSPACE_SRC}/${PKG}"

