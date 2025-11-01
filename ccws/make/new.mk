new: assert_PKG_arg_must_be_specified
	mkdir -p "${CCWS_SOURCE_DIR}"
	${MAKE} new_${OS_DISTRO_BUILD}
	mkdir -p "${CCWS_SOURCE_DIR}/${PKG}/include/${PKG}"
	cd "${CCWS_SOURCE_DIR}/${PKG}"; git init
	find "${CCWS_SOURCE_DIR}/${PKG}" -type f | xargs sed -i "s/@@PACKAGE@@/${PKG}/g"
	find "${CCWS_SOURCE_DIR}/${PKG}" -type f | xargs sed -i "s/@@AUTHOR@@/${AUTHOR}/g"
	find "${CCWS_SOURCE_DIR}/${PKG}" -type f | xargs sed -i "s/@@EMAIL@@/${EMAIL}/g"
	find "${CCWS_SOURCE_DIR}/${PKG}" -type f | xargs sed -i "s/@@LICENSE@@/${LICENSE}/g"

new_bionic: new_focal
	# passthrough

new_focal:
	cp -R ${CCWS_DIR}/examples/pkg_catkin "${CCWS_SOURCE_DIR}/${PKG}"

new_jammy:
	cp -R ${CCWS_DIR}/examples/pkg_ament "${CCWS_SOURCE_DIR}/${PKG}"

new_%: new_jammy
	#

