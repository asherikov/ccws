TEST_REGEX?=.*
TEST_PKG_LIST=${CCWS_BUILD_DIR}/ccws.tests.packages
TEST_PKG_LIST_EXCEPT=${CCWS_BUILD_DIR}/ccws.tests.exceptions.packages

# CDash submission of test results, see ccws/tools/bin/ccws_cdash_submit.sh
# (post-hoc: submits whatever test targets have left in the artifacts directory;
# submission is triggered automatically by test targets if both variables below
# are set in the environment or on the command line)
CDASH_URL?=
CDASH_PROJECT?=
# authentication token, must be provided via environment, e.g. CI secrets
CDASH_TOKEN?=
# site name, e.g. CI runner identifier, defaults to hostname
CDASH_SITE?=$(shell hostname)
# build name, defaults to profile / ROS distro / OS distro, package name is appended
CDASH_BUILD_NAME?=${CCWS_BUILD_PROFILES_ID}-${ROS_DISTRO}-${OS_DISTRO_BUILD}
# if nonempty, print submission commands instead of executing them
CDASH_DRY_RUN?=

export CDASH_URL CDASH_PROJECT CDASH_TOKEN CDASH_DRY_RUN

wslist_test:
	@${MAKE_QUIET} wslist | sort > "${TEST_PKG_LIST}"
	@(cat "${CCWS_SOURCE_DIR}/.ccws/ccws.tests.exceptions.packages" 2> /dev/null | sed -e 's/[[:space:]]*#.*//' -e '/^[[:space:]]*$$/d' || true) | sort > "${TEST_PKG_LIST_EXCEPT}"
	@comm -23 "${TEST_PKG_LIST}" "${TEST_PKG_LIST_EXCEPT}" | ${CCWS_XARGS} sh -c "if [ -d '${CCWS_BUILD_DIR}/{}' ]; then echo {}; fi"

# generic test target, it is recommended to use more specific targets below
wstest_generic:
	${MAKE_QUIET} wslist_test | ${CCWS_XARGS} sh -c "${MAKE} ${TEST_TARGET} PKG={} || exit ${EXIT_STATUS}"

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
	test ! -d '${CCWS_BUILD_DIR}/${PKG}' \
		|| (bash -c "time ( source ${CCWS_ROOT}/setup.bash ${CCWS_BUILD_PROFILES} test ${EXEC_PROFILE}; \
		colcon \
		--log-base \$${CCWS_LOG_DIR} \
		test \
		--event-handlers console_direct+ \
		--merge-install \
		--executor sequential \
		--ctest-args --output-on-failure -j ${JOBS} \
		--build-base \"\$${CCWS_BUILD_DIR}\" \
		--install-base \"\$${CCWS_INSTALL_DIR_BUILD}\" \
		--base-paths "${CCWS_SOURCE_DIR}" \
		--test-result-base \$${CCWS_LOG_DIR}/testing \
		--packages-select ${PKG} )" \
		&& ${MAKE} showtestresults || ${MAKE} showtestresults)
	test -d '${CCWS_BUILD_DIR}/${PKG}' || echo "CCWS: ${PKG} was not built?"

ctest: assert_PKG_arg_must_be_specified
	echo '${PKG}' | sed 's/ /\n/g' | ${CCWS_XARGS} bash -c \
		"time ( source ${CCWS_ROOT}/setup.bash ${CCWS_BUILD_PROFILES} test ${EXEC_PROFILE}; \
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

test_results:
	# shows fewer tests
	test -z '${PKG}' || echo '${PKG}' | sed 's/ /\n/g' | ${CCWS_XARGS} bash -c "${SETUP_SCRIPT}; ${MAKE} private_test_results_pkg PKG={}"
	test -n '${PKG}' || ${MAKE} private_test_results_ws
	#bash -c "${SETUP_SCRIPT}; catkin_test_results \$${CCWS_BUILD_DIR}/${PKG}"

private_test_results_ws:
	@mkdir -p ${CCWS_ARTIFACTS_DIR}
	@test -z "${CDASH_URL}${CDASH_PROJECT}" || ${MAKE} wscdash_submit PKG=${PKG}
	@bash -c "${SETUP_SCRIPT}; colcon --log-base /dev/null test-result --all --verbose --test-result-base ${CCWS_ARTIFACTS_DIR}"

private_test_results_pkg: assert_PKG_arg_must_be_specified
	@mkdir -p ${CCWS_ARTIFACTS_DIR}/${PKG}/
	@cp -R ${CCWS_BUILD_DIR}/${PKG}/Testing ${CCWS_ARTIFACTS_DIR}/${PKG}/ 2> /dev/null || true
	@cp -R ${CCWS_BUILD_DIR}/${PKG}/test_results ${CCWS_ARTIFACTS_DIR}/${PKG}/ 2> /dev/null || true
	# submission has to happen before `colcon test-result`, which fails on failed tests
	@test -z "${CDASH_URL}${CDASH_PROJECT}" || ${MAKE} cdash_submit PKG=${PKG}
	@colcon --log-base /dev/null test-result --all --test-result-base ${CCWS_BUILD_DIR}/${PKG}

test_list: assert_PKG_arg_must_be_specified
	bash -c "time ( source ${CCWS_ROOT}/setup.bash ${CCWS_BUILD_PROFILES} test ${EXEC_PROFILE} \
		&& echo '${PKG}' | sed 's/ /\n/g' | ${CCWS_XARGS} ctest --show-only --test-dir \"\$${CCWS_BUILD_DIR}/{}\")"


assert_CDASH_must_be_configured:
	test "${CDASH_URL}" != "" > /dev/null
	test "${CDASH_PROJECT}" != "" > /dev/null

# submits results of specified packages,
#   make cdash_submit PKG="pkg1 pkg2" CDASH_URL=... CDASH_PROJECT=... [CDASH_DRY_RUN=on]
cdash_submit: assert_PKG_arg_must_be_specified assert_CDASH_must_be_configured
	echo '${PKG}' | sed 's/ /\n/g' | ${CCWS_XARGS} ${CCWS_TOOLS_DIR}/bin/ccws_cdash_submit.sh "${CCWS_ARTIFACTS_DIR}/{}" "${CDASH_SITE}" "${CDASH_BUILD_NAME}-{}"

# submits results of all packages that have artifacts for the current profile
wscdash_submit: assert_CDASH_must_be_configured
	find "${CCWS_ARTIFACTS_DIR}" -mindepth 1 -maxdepth 1 -type d 2> /dev/null | sed -e 's=.*/==' | ${CCWS_XARGS} ${MAKE_QUIET} cdash_submit PKG={}
