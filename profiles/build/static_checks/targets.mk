bprof_static_checks_install_build: bprof_common_install_build
	#pip3 install cpplint
	sudo ${APT_INSTALL} \
		cppcheck \
		flawfinder \
		yamllint \
		shellcheck
	sudo ${MAKE} bprof_static_checks_install_build_${OS_DISTRO_BUILD}

#ubuntu18
bprof_static_checks_install_build_bionic:
	${APT_INSTALL} python-catkin-lint

#ubuntu20
bprof_static_checks_install_build_focal:
	${APT_INSTALL} python3-catkin-lint


static_checks_build:
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
	mkdir -p ${WORKSPACE_DIR}/build/$@
	bash -c "${SETUP_SCRIPT}; \
		EXCEPTIONS=\$$(echo \$${CCWS_STATIC_DIR_EXCEPTIONS} | sed -e 's/:/ -i /g'); \
		cppcheck \
			${WORKSPACE_DIR}/src \
			--relative-paths \
			--quiet --verbose --force \
			--template='[{file}:{line}]  {severity}  {id}  {message}' \
			--language=c++ --std=c++14 \
			--enable=warning \
			--enable=style \
			--enable=performance \
			--enable=portability \
			--suppress=uninitMemberVar \
			--suppress=syntaxError \
			--suppress=useInitializationList \
			\$${EXCEPTIONS} \
			3>&1 1>&2 2>&3 \
			| tee '${WORKSPACE_DIR}/build/$@/cppcheck.err' "
	test ! -s '${WORKSPACE_DIR}/build/$@/cppcheck.err' || exit 1


cpplint:
	bash -c "${SETUP_SCRIPT}; \
		EXCEPTIONS=\$$(echo \$${CCWS_STATIC_DIR_EXCEPTIONS} | sed -e 's/:/ --exclude=/g'); \
		cpplint \
		\$${EXCEPTIONS} \
		--filter=-whitespace,-runtime/casting,-runtime/indentation_namespace,-readability/casting,-runtime/references,-readability/braces,-readability/namespace,-build/include_subdir,-build/header_guard,-build/include_order,-build/namespaces,-build/c++11,-readability/alt_tokens,-readability/todo,-build/include \
		--quiet --recursive src"


# internal target
static_checks_generic_dir_filter:
	mkdir -p ${WORKSPACE_DIR}/build/${TARGET}
	echo -n "cat ${WORKSPACE_DIR}/build/${TARGET}/input" > ${WORKSPACE_DIR}/build/${TARGET}/filter
	bash -c "${SETUP_SCRIPT}; \
		echo \$${CCWS_STATIC_DIR_EXCEPTIONS} | sed -e 's/:/ :/g' -e 's=:\([[:graph:]]*\)= | grep -v \"\1\" =g' >> ${WORKSPACE_DIR}/build/${TARGET}/filter"


flawfinder:
	${MAKE} static_checks_generic_dir_filter TARGET=$@
	find ${WORKSPACE_DIR}/src -iname '*.cpp' -or -iname '*.h' > ${WORKSPACE_DIR}/build/$@/input
	bash -c " \
		source ${WORKSPACE_DIR}/build/$@/filter > ${WORKSPACE_DIR}/build/$@/input.filtered; \
		cat ${WORKSPACE_DIR}/build/shellcheck/input.filtered | xargs  --max-procs=${JOBS} -I {} flawfinder --singleline --dataonly --quiet --minlevel=0 {}"


yamllint:
	${MAKE} static_checks_generic_dir_filter TARGET=$@
	find ${WORKSPACE_DIR}/src -iname '*.yaml' > ${WORKSPACE_DIR}/build/$@/input
	bash -c "${SETUP_SCRIPT}; \
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
	bash -c "${SETUP_SCRIPT}; \
		( find ${BUILD_PROFILES_DIR} -maxdepth 2 -iname '*.sh' -or -iname '*.bash' \
			&& find ${WORKSPACE_DIR}/scripts -iname '*.sh' -or -iname '*.bash' \
			&& find ${WORKSPACE_DIR} -maxdepth 2 -iname '*.sh' -or -iname '*.bash' ) \
			> ${WORKSPACE_DIR}/build/$@/input; \
		find ${WORKSPACE_DIR}/src ${BUILD_PROFILES_DIR}/*/vendor -iname '*.sh' -or -iname '*.bash' >> ${WORKSPACE_DIR}/build/$@/input || true; \
		source ${WORKSPACE_DIR}/build/$@/filter > ${WORKSPACE_DIR}/build/$@/input.filtered; \
		cat ${WORKSPACE_DIR}/build/$@/input.filtered | xargs --max-procs=${JOBS} -I {} shellcheck -x \$${CCWS_SHELLCHECK_EXCEPTIONS} {}"


catkin_lint:
	# --skip-pkg <pkg>
	bash -c "${SETUP_SCRIPT}; \
		DIR_EXCEPTIONS=\$$(echo \$${CCWS_STATIC_DIR_EXCEPTIONS} | sed -e 's/:/ --skip-path /g'); \
		PKG_EXCEPTIONS=\$$(echo \$${CCWS_STATIC_PKG_EXCEPTIONS} | sed -e 's/:/ --skip-pkg /g'); \
		echo \$${DIR_EXCEPTIONS}; \
		echo \$${PKG_EXCEPTIONS}; \
		catkin_lint --severity-level 2 --strict --explain \
		\$${CCWS_CATKIN_LINT_EXCEPTIONS} \
		\$${DIR_EXCEPTIONS} \
		\$${PKG_EXCEPTIONS} \
		src/"

