STATIC_CHECKS_SETUP_SCRIPT=source ${WORKSPACE_DIR}/profiles/static_checks/setup.bash

static_checks_host_install:
	#pip3 install cpplint
	sudo ${APT_INSTALL} \
		cppcheck \
		flawfinder \
		yamllint \
		shellcheck
	sudo ${MAKE} static_checks_host_install_${OS_DISTRO}

#ubuntu18
static_checks_host_install_bionic:
	${APT_INSTALL} python-catkin-lint

#ubuntu20
static_checks_host_install_focal:
	${APT_INSTALL} python3-catkin-lint


static_checks:
	${MAKE} cppcheck
	${MAKE} catkin_lint
	${MAKE} yamllint
	#${MAKE} cpplint
	${MAKE} shellcheck
	# false positives
	-${MAKE} flawfinder


cppcheck:
	# suppressions:
	# 	uninitMemberVar -- triggers on a lot of valid code, e.g., when initializing in SetUp()
	# 	syntaxError -- has issues with templated methods and test fixtures.
	# 	useInitializationList -- initialization in the body of the constructor is ok
	#
	# --inconclusive -- can be used to catch some extra issues
	# --error-exitcode=1 -- fails with no errors printed
	bash -c "${STATIC_CHECKS_SETUP_SCRIPT}; \
		EXCEPTIONS=\$$(echo \$${CCWS_STATIC_DIR_EXCEPTIONS} | sed -e 's/:/ -i /g'); \
		cppcheck \
			\$${CCWS_WORKSPACE_DIR}/src \
			--relative-paths \
			--quiet --verbose --force \
			--template='[{file}:{line}]  {severity}  {id}  {message}' \
			--language=c++ --std=c++11 \
			--enable=warning \
			--enable=style \
			--enable=performance \
			--enable=portability \
			--suppress=uninitMemberVar \
			--suppress=syntaxError \
			--suppress=useInitializationList \
			\$${EXCEPTIONS} \
			3>&1 1>&2 2>&3 | tee \$${CCWS_ARTIFACTS_DIR}/cppcheck.err; \
		test ! -s \$${CCWS_ARTIFACTS_DIR}/cppcheck.err || exit 1"


cpplint:
	bash -c "${STATIC_CHECKS_SETUP_SCRIPT}; \
		EXCEPTIONS=\$$(echo \$${CCWS_STATIC_DIR_EXCEPTIONS} | sed -e 's/:/ --exclude=/g'); \
		cpplint \
		\$${EXCEPTIONS} \
		--filter=-whitespace,-runtime/casting,-runtime/indentation_namespace,-readability/casting,-runtime/references,-readability/braces,-readability/namespace,-build/include_subdir,-build/header_guard,-build/include_order,-build/namespaces,-build/c++11,-readability/alt_tokens,-readability/todo,-build/include \
		--quiet --recursive src"


# internal target
static_checks_generic_dir_filter:
	mkdir -p ${WORKSPACE_DIR}/build/${TARGET}
	echo -n "cat ${WORKSPACE_DIR}/build/${TARGET}/input" > ${WORKSPACE_DIR}/build/${TARGET}/filter
	bash -c "${STATIC_CHECKS_SETUP_SCRIPT}; \
		echo ${CCWS_STATIC_DIR_EXCEPTIONS} | sed 's= \([[:graph:]]*\)= | grep -v \"\1\" =g' >> ${WORKSPACE_DIR}/build/${TARGET}/filter"


flawfinder:
	${MAKE} static_checks_generic_dir_filter TARGET=$@
	find ${WORKSPACE_DIR}/src -iname '*.cpp' -or -iname '*.h' > ${WORKSPACE_DIR}/build/$@/input
	bash -c " \
		source ${WORKSPACE_DIR}/build/$@/filter > ${WORKSPACE_DIR}/build/$@/input.filtered; \
		cat ${WORKSPACE_DIR}/build/shellcheck/input.filtered | xargs  --max-procs=${JOBS} -I {} flawfinder --singleline --dataonly --quiet --minlevel=0 {}"


yamllint:
	${MAKE} static_checks_generic_dir_filter TARGET=$@
	find ${WORKSPACE_DIR}/src -iname '*.yaml' > ${WORKSPACE_DIR}/build/$@/input
	bash -c " \
		source ${WORKSPACE_DIR}/build/$@/filter > ${WORKSPACE_DIR}/build/$@/input.filtered; \
		cat ${WORKSPACE_DIR}/build/$@/input.filtered | xargs --max-procs=${JOBS} -I {} \
		env LC_ALL=C.UTF-8 yamllint -d \"{extends: default, \
                      rules: { \
                        colons: {max-spaces-before: 0, max-spaces-after: -1}, \
                        commas: disable, \
                        comments: {require-starting-space: false, min-spaces-from-content: 0}, \
                        document-start: disable, \
                        indentation: {spaces: consistent, indent-sequences: consistent}, \
                        line-length: disable, \
                        trailing-spaces: disable, \
                        new-line-at-end-of-file: disable, \
                        comments-indentation: disable, \
                        empty-lines: {max: 5, max-end: 1}}}\" {}"


shellcheck:
	${MAKE} static_checks_generic_dir_filter TARGET=$@
	bash -c "${STATIC_CHECKS_SETUP_SCRIPT}; \
		( find \$${CCWS_WORKSPACE_DIR}/profiles -maxdepth 2 -iname '*.sh' -or -iname '*.bash' && \
			find \$${CCWS_WORKSPACE_DIR}/src \$${CCWS_WORKSPACE_DIR}/scripts -iname '*.sh' -or -iname '*.bash' ) \
			> ${WORKSPACE_DIR}/build/$@/input; \
		source ${WORKSPACE_DIR}/build/$@/filter > ${WORKSPACE_DIR}/build/$@/input.filtered; \
		cat ${WORKSPACE_DIR}/build/$@/input.filtered | xargs --max-procs=${JOBS} -I {} shellcheck -x \$${CCWS_SHELLCHECK_EXCEPTIONS} {}"


CATKIN_LINT_COMMON_IGNORES=--ignore package_path_name \
						   --ignore unsorted_list \
						   --ignore description_meaningless \
						   --ignore critical_var_append \
						   --ignore missing_export_lib \
						   --ignore no_catkin_component \
						   --ignore description_boilerplate \
						   --ignore uninstalled_script \
						   --ignore ambiguous_include_path \
						   --ignore unknown_package

catkin_lint:
	# --skip-pkg <pkg>
	bash -c "${STATIC_CHECKS_SETUP_SCRIPT}; catkin_lint --severity-level 2 --strict \
		${CATKIN_LINT_COMMON_IGNORES} \
		src/"

