BASE_BUILD_PROFILE?=common

assert_BUILD_PROFILE_must_exist:
	test -d "${BUILD_PROFILES_DIR}/${BUILD_PROFILE}"

assert_BUILD_PROFILE_must_not_exist:
	test ! -d "${BUILD_PROFILES_DIR}/${BUILD_PROFILE}"

bprof_new: assert_BUILD_PROFILE_must_not_exist
	${MAKE} assert_BUILD_PROFILE_must_exist BUILD_PROFILE=${BASE_BUILD_PROFILE}
	cp -R "${WORKSPACE_DIR}/profiles/template_build" "${BUILD_PROFILES_DIR}/${BUILD_PROFILE}"
	find "${BUILD_PROFILES_DIR}/${BUILD_PROFILE}" -type f | xargs sed -i "s/@@BUILD_PROFILE@@/${BUILD_PROFILE}/g"
	find "${BUILD_PROFILES_DIR}/${BUILD_PROFILE}" -type f | xargs sed -i "s/@@BASE_BUILD_PROFILE@@/${BASE_BUILD_PROFILE}/g"
