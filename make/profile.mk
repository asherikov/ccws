BASE_BUILD_PROFILE?=common

assert_BUILD_PROFILE_must_exist:
	test -f "${BUILD_PROFILES_DIR}/${BUILD_PROFILE}/setup.bash"

assert_BASE_BUILD_PROFILE_must_exist:
	test -f "${BUILD_PROFILES_DIR}/${BASE_BUILD_PROFILE}/setup.bash"

assert_BUILD_PROFILE_must_not_exist:
	test ! -d "${BUILD_PROFILES_DIR}/${BUILD_PROFILE}"

assert_EXEC_PROFILE_must_not_exist:
	test ! -d "${EXEC_PROFILES_DIR}/${EXEC_PROFILE}"

bp_new: assert_BUILD_PROFILE_must_not_exist
	${MAKE} assert_BUILD_PROFILE_must_exist BUILD_PROFILE=${BASE_BUILD_PROFILE}
	cp -R "${WORKSPACE_DIR}/profiles/template_build" "${BUILD_PROFILES_DIR}/${BUILD_PROFILE}"
	find "${BUILD_PROFILES_DIR}/${BUILD_PROFILE}" -type f | xargs sed -i "s/@@BUILD_PROFILE@@/${BUILD_PROFILE}/g"
	find "${BUILD_PROFILES_DIR}/${BUILD_PROFILE}" -type f | xargs sed -i "s/@@BASE_BUILD_PROFILE@@/${BASE_BUILD_PROFILE}/g"

ep_new: assert_EXEC_PROFILE_must_not_exist
	cp -R "${WORKSPACE_DIR}/profiles/template_exec" "${EXEC_PROFILES_DIR}/${EXEC_PROFILE}"
	find "${EXEC_PROFILES_DIR}/${EXEC_PROFILE}" -type f | xargs sed -i "s/@@EXEC_PROFILE@@/${EXEC_PROFILE}/g"
