# see profiles/build/common/cmake/ccws_vcpkg_install.cmake
# not supported:
#	some packages have issues on Linux
export CCWS_VCPKG_VERSION?=2023.07.21
export CCWS_VCPKG_ROOT?="${CCWS_CACHE}/vcpkg_${CCWS_VCPKG_VERSION}"


install_vcpkg:
	test -d ${CCWS_VCPKG_ROOT} || git clone -b ${CCWS_VCPKG_VERSION} https://github.com/Microsoft/vcpkg.git "${CCWS_VCPKG_ROOT}"
	cd "${CCWS_VCPKG_ROOT}"; test -f ./vcpkg || ./bootstrap-vcpkg.sh
	cd "${CCWS_VCPKG_ROOT}"; ./vcpkg install vcpkg-cmake

vcpkg_generate_overlays: assert_PKG_arg_must_be_specified
	${CCWS_VCPKG_ROOT}/vcpkg depend-info "${PKG}" | cut -f 2 -d ':' | sed -e 's/,/\n/g' -e 's/ //g' -e '/^$$/d' | sort | uniq | grep -v 'vcpkg' \
		| xargs -I {} ${MAKE} vcpkg_generate_overlay PKG={}

vcpkg_generate_overlay: assert_PKG_arg_must_be_specified
	# https://devblogs.microsoft.com/cppblog/using-system-package-manager-dependencies-with-vcpkg/
	test "${OVERLAY_DIR}" != ""
	mkdir -p "${OVERLAY_DIR}/${PKG}"
	echo "{ \"name\": \"${PKG}\", \"version\": \"1.0.0\" }" > "${OVERLAY_DIR}/${PKG}/vcpkg.json"
	echo 'set(VCPKG_POLICY_EMPTY_PACKAGE enabled)' > "${OVERLAY_DIR}/${PKG}/portfile.cmake"
