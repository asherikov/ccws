bp_cppcheck_build: assert_BASE_BUILD_PROFILE_must_exist
	rm -Rf "${WORKSPACE_DIR}/build/${BUILD_PROFILE}/"
	mkdir -p "${WORKSPACE_DIR}/build/${BUILD_PROFILE}/"
	bash -c "${SETUP_SCRIPT}; \
		echo '${SETUP_SCRIPT}'; \
		echo \"<<\$${CCWS_STATIC_DIR_EXCEPTIONS}>>>\"; \
		echo $${CCWS_STATIC_DIR_EXCEPTIONS} > '${WORKSPACE_DIR}/build/${BUILD_PROFILE}/suppressions'"
	sed -i -e 's/:/\n/g' '${WORKSPACE_DIR}/build/${BUILD_PROFILE}/suppressions'
	sed -i -e '/^$$/d' '${WORKSPACE_DIR}/build/${BUILD_PROFILE}/suppressions'
	sed -i -e 's/^/*:/' -e 's/$$/*/' '${WORKSPACE_DIR}/build/${BUILD_PROFILE}/suppressions'
	bash -c "${SETUP_SCRIPT}; \
		cppcheck \
			-j ${JOBS} \
			--relative-paths \
			--template='[{file}:{line}]  {severity}  {id}  {message}' \
			--language=c++ --std=c++\$${CCWS_CXX_STANDARD} \
			--enable=warning \
			--enable=style \
			--enable=performance \
			--enable=portability \
			--inline-suppr \
			-i /usr \
			${CCWS_CPPCHECK_EXCEPTIONS} \
			--suppressions-list='${WORKSPACE_DIR}/build/${BUILD_PROFILE}/suppressions' \
			--project='${WORKSPACE_DIR}/build/${BASE_BUILD_PROFILE}/compile_commands.json' \
			3>&1 1>&2 2>&3 \
			{} \
			| tee --append '${WORKSPACE_DIR}/build/${BUILD_PROFILE}/cppcheck.err' "
	test ! -s '${WORKSPACE_DIR}/build/${BUILD_PROFILE}/cppcheck.err' || exit 1


bp_cppcheck_install_build: bp_common_install_build
	sudo ${APT_INSTALL} cppcheck
