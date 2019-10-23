STATIC_CHECKS_INCLUDED=true
STATIC_CHECKS_SETUP_SCRIPT=source ${WORKSPACE_DIR}/profiles/common/setup.bash

install_static_checkers:
	#pip3 install cpplint
	apt install cppcheck
	apt install flawfinder
	apt install yamllint
	apt install shellcheck
	apt install python-catkin-lint


static_check:
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
	bash -c "${STATIC_CHECKS_SETUP_SCRIPT}; cppcheck \
		\$${CCW_WORKSPACE_DIR}/src \
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
		`echo \$${CCW_STATIC_PATH_EXCEPTIONS} | sed 's/ / -i /g'` \
	3>&1 1>&2 2>&3 | tee \$${CCW_ARTIFACTS_DIR}/cppcheck.err; \
	test -s \$${CCW_ARTIFACTS_DIR}/cppcheck.err"


cpplint:
	bash -c "${STATIC_CHECKS_SETUP_SCRIPT}; cpplint \
		`echo \$${CCW_STATIC_PATH_EXCEPTIONS} | sed 's/ / --exclude=/g'` \
		--filter=-whitespace,-runtime/casting,-runtime/indentation_namespace,-readability/casting,-runtime/references,-readability/braces,-readability/namespace,-build/include_subdir,-build/header_guard,-build/include_order,-build/namespaces,-build/c++11,-readability/alt_tokens,-readability/todo,-build/include \
		--quiet --recursive src"


flawfinder:
	bash -c "${STATIC_CHECKS_SETUP_SCRIPT}; find \$${CCW_WORKSPACE_DIR}/src -iname '*.cpp' -or -iname "*.h" \
		`echo \$${CCW_STATIC_PATH_EXCEPTIONS} | sed 's/ \([[:graph:]]*\)/ | grep -v \"\1\" /g'`" \
		| xargs  --max-procs=${JOBS} -I {} flawfinder --singleline --dataonly --quiet --minlevel=0 {}


yamllint:
	bash -c "${STATIC_CHECKS_SETUP_SCRIPT}; find \$${CCW_WORKSPACE_DIR}/src -iname '*.yaml' \
		`echo \$${CCW_STATIC_PATH_EXCEPTIONS} | sed 's/ \([[:graph:]]*\)/ | grep -v \"\1\" /g'`" \
		| xargs --max-procs=${JOBS} -I {} \
		env LC_ALL=C.UTF-8 yamllint -d "{extends: default, \
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
                        empty-lines: {max: 5, max-end: 1}}}" {}

shellcheck:
	bash -c "${STATIC_CHECKS_SETUP_SCRIPT}; find \$${CCW_WORKSPACE_DIR}/scripts \$${CCW_WORKSPACE_DIR}/src \$${CCW_WORKSPACE_DIR}/profiles -iname '*.sh' -or -iname "*.bash" \
		`echo \$${CCW_STATIC_PATH_EXCEPTIONS} | sed 's/ \([[:graph:]]*\)/ | grep -v \"\1\" /g'`" \
		| xargs --max-procs=${JOBS} -I {} \
		shellcheck -x {}



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

