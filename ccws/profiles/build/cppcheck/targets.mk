bp_cppcheck_build: assert_multiple_valid_profiles_must_be_provided
	rm -Rf "${CCWS_BUILD_DIR}/"
	mkdir -p "${CCWS_BUILD_DIR}/"
	${MAKE} bp_copy_compile_commands_tail
	bash -c "${SETUP_SCRIPT}; \
		echo '${SETUP_SCRIPT}'; \
		echo $${CCWS_STATIC_DIR_EXCEPTIONS} > '${CCWS_BUILD_DIR}/suppressions'"
	sed -i -e 's/:/\n/g' '${CCWS_BUILD_DIR}/suppressions'
	sed -i -e '/^$$/d' '${CCWS_BUILD_DIR}/suppressions'
	sed -i -e 's/^/*:/' -e 's/$$/*/' '${CCWS_BUILD_DIR}/suppressions'
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
			\$${CCWS_CPPCHECK_EXCEPTIONS} \
			--suppressions-list='${CCWS_BUILD_DIR}/suppressions' \
			--project='${CCWS_BUILD_DIR}/compile_commands.json' \
			3>&1 1>&2 2>&3 \
			| tee --append '${CCWS_BUILD_DIR}/cppcheck.err' "
	test ! -s '${CCWS_BUILD_DIR}/cppcheck.err' || exit 1


bp_cppcheck_install_build: install_ccws_deps
	sudo ${APT_INSTALL} cppcheck
