TEST_REGEX?=.*

# generic test target, it is recommended to use more specific targets below
wstest_generic:
	${MAKE_QUIET} wslist | xargs -I '{}' sh -c "${MAKE} ${TEST_TARGET} PKG={} || exit ${EXIT_STATUS}"

# stops on first error
wstest_faststop:
	${MAKE_QUIET} wstest_generic TEST_TARGET=test EXIT_STATUS=255

# stops on first error
wsctest_faststop:
	${MAKE_QUIET} wstest_generic TEST_TARGET=ctest EXIT_STATUS=255

wstest:
	${MAKE_QUIET} wstest_generic TEST_TARGET=test EXIT_STATUS=1

wsctest:
	${MAKE_QUIET} wstest_generic TEST_TARGET=ctest EXIT_STATUS=1


# this target uses colcon and unlike `ctest` target does not respect `--output-on-failure`
test: assert_PKG_arg_must_be_specified
	bash -c "time ( source ${WORKSPACE_DIR}/setup.bash ${BUILD_PROFILE} test ${EXEC_PROFILE}; \
		colcon \
		--log-base \$${CCWS_LOG_DIR} \
		test \
		--event-handlers console_direct+ \
		--merge-install \
		--executor sequential \
		--ctest-args --output-on-failure -j ${JOBS} \
		--build-base \"\$${CCWS_BUILD_DIR}\" \
		--install-base \"\$${CCWS_INSTALL_DIR_BUILD}\" \
		--base-paths "${WORKSPACE_SRC}" \
		--test-result-base \$${CCWS_LOG_DIR}/testing \
		--packages-select ${PKG} )" \
		&& ${MAKE} showtestresults || ${MAKE} showtestresults

ctest: assert_PKG_arg_must_be_specified
	echo '${PKG}' | sed 's/ /\n/g' | xargs --no-run-if-empty -I {} bash -c \
		"time ( source ${WORKSPACE_DIR}/setup.bash ${BUILD_PROFILE} test ${EXEC_PROFILE}; \
		mkdir -p \"\$${CCWS_ARTIFACTS_DIR}\"; \
		cd \"\$${CCWS_BUILD_DIR}/{}\"; \
		time ctest --schedule-random --output-on-failure --output-log \"\$${CCWS_ARTIFACTS_DIR}/ctest_{}.log\" -j ${JOBS} --tests-regex '${TEST_REGEX}')" \
		&& ${MAKE} showtestresults || ${MAKE} showtestresults

test_with_deps: assert_PKG_arg_must_be_specified
	${MAKE_QUIET} wstest_generic TEST_TARGET=test EXIT_STATUS=1

ctest_with_deps: assert_PKG_arg_must_be_specified
	${MAKE_QUIET} wstest_generic TEST_TARGET=ctest EXIT_STATUS=1


# compatibility
showtestresults: test_results

test_results: assert_PKG_arg_must_be_specified
	# shows fewer tests
	echo '${PKG}' | sed 's/ /\n/g' | xargs --no-run-if-empty -I {} bash -c "${SETUP_SCRIPT}; \
		mkdir -p \$${CCWS_ARTIFACTS_DIR}/{}/; \
		cp -R \$${CCWS_BUILD_DIR}/{}/Testing \$${CCWS_ARTIFACTS_DIR}/{}/ || true; \
		cp -R \$${CCWS_BUILD_DIR}/{}/test_results \$${CCWS_ARTIFACTS_DIR}/{}/ || true; \
		colcon --log-base /dev/null test-result --all --test-result-base \$${CCWS_BUILD_DIR}/{}"
	#bash -c "${SETUP_SCRIPT}; catkin_test_results \$${CCWS_BUILD_DIR}/${PKG}"

test_list: assert_PKG_arg_must_be_specified
	bash -c "time ( source ${WORKSPACE_DIR}/setup.bash ${BUILD_PROFILE} test ${EXEC_PROFILE} \
		&& echo '${PKG}' | sed 's/ /\n/g' | xargs --no-run-if-empty -I {} ctest --show-only --test-dir \"\$${CCWS_BUILD_DIR}/{}\")"

