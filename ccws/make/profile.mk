assert_BUILD_PROFILES_must_exist:
	echo "${CCWS_BUILD_PROFILES}" | sed -e 's/,/\n/g' | xargs -I {} test -f "${BUILD_PROFILES_DIR}/{}/setup.bash"

assert_SECONDARY_BUILD_PROFILE_must_exist:
	test -f "${BUILD_PROFILES_DIR}/${CCWS_SECONDARY_BUILD_PROFILE}/setup.bash"

bp_new:
	test ! -d "${BUILD_PROFILES_DIR}/${CCWS_PRIMARY_BUILD_PROFILE}"
	${MAKE} assert_BUILD_PROFILES_must_exist BUILD_PROFILE=${CCWS_SECONDARY_BUILD_PROFILE}
	cp -R "${CCWS_DIR}/profiles/template_build" "${BUILD_PROFILES_DIR}/${CCWS_PRIMARY_BUILD_PROFILE}"
	find "${BUILD_PROFILES_DIR}/${CCWS_PRIMARY_BUILD_PROFILE}" -type f \
		| xargs sed -i -e "s/@@BUILD_PROFILE@@/${CCWS_PRIMARY_BUILD_PROFILE}/g" -e "s/@@BASE_BUILD_PROFILE@@/${CCWS_SECONDARY_BUILD_PROFILE}/g"

ep_new:
	test ! -d "${EXEC_PROFILES_DIR}/${EXEC_PROFILE}"
	cp -R "${CCWS_DIR}/profies/template_exec" "${EXEC_PROFILES_DIR}/${EXEC_PROFILE}"
	find "${EXEC_PROFILES_DIR}/${EXEC_PROFILE}" -type f | xargs sed -i "s/@@EXEC_PROFILE@@/${EXEC_PROFILE}/g"
