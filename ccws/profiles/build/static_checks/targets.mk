bp_static_checks_install_build: bp_common_install_build
	#${PIP3_INSTALL} cpplint
	sudo ${APT_INSTALL} \
		cppcheck \
		flawfinder \
		yamllint \
		shellcheck
	sudo ${MAKE} bp_static_checks_install_build_${OS_DISTRO_BUILD}
	${MAKE} bp_static_checks_install_build_python

#ubuntu18
bp_static_checks_install_build_bionic:
	${APT_INSTALL} python-catkin-lint

#ubuntu20
bp_static_checks_install_build_focal:
	${APT_INSTALL} python3-catkin-lint

#ubuntu22
bp_static_checks_install_build_jammy: install_python3
	${PIP3_INSTALL} catkin-lint

bp_static_checks_install_build_python: install_python3
	${PIP3_INSTALL} pylint
	${PIP3_INSTALL} flake8
	${PIP3_INSTALL} mypy
	# required by mypy
	${PIP3_INSTALL} types-PyYAML


bp_static_checks_build:
	${MAKE} cppcheck
	${MAKE} catkin_lint
	${MAKE} yamllint
	#${MAKE} cpplint
	${MAKE} shellcheck
	# false positives
	-${MAKE} flawfinder
	${MAKE} bp_static_checks_build_python

bp_static_checks_build_python:
	${MAKE} pylint
	${MAKE} flake8
	${MAKE} mypy



cppcheck:
	# --inconclusive -- can be used to catch some extra issues
	# --error-exitcode=1 -- fails with no errors printed
	#
	# Header files are specified explicitly since cppcheck ignores them if
	# directory is provided as an input, the correct way is probably to specify
	# header paths with `-I` flags but that is not trivial in a workspace,
	# might require parsing compilation commands from cmake.
	${MAKE} static_checks_generic_dir_filter TARGET=$@
	find "${WORKSPACE_SRC}" -type f -iname '*.hpp' -or -iname "*.cpp" -or -iname "*.h" > ${WORKSPACE_DIR}/build/${BUILD_PROFILE}/$@/input
	rm -f '${WORKSPACE_DIR}/build/${BUILD_PROFILE}/$@/cppcheck.err'
	bash -c "${SETUP_SCRIPT}; \
		source ${WORKSPACE_DIR}/build/${BUILD_PROFILE}/$@/filter > ${WORKSPACE_DIR}/build/${BUILD_PROFILE}/$@/input.filtered; \
		cat ${WORKSPACE_DIR}/build/${BUILD_PROFILE}/$@/input.filtered | xargs --max-procs=${JOBS} --no-run-if-empty -I {} \
		cppcheck \
			-j 1 \
			--relative-paths \
			--quiet --verbose --force \
			--template='[{file}:{line}]  {severity}  {id}  {message}' \
			--language=c++ --std=c++\$${CCWS_CXX_STANDARD} \
			--enable=warning \
			--enable=style \
			--enable=performance \
			--enable=portability \
			--inline-suppr \
			\$${CCWS_CPPCHECK_EXCEPTIONS} \
			3>&1 1>&2 2>&3 \
			{} \
			| tee --append '${WORKSPACE_DIR}/build/${BUILD_PROFILE}/$@/cppcheck.err' "
	test ! -s '${WORKSPACE_DIR}/build/${BUILD_PROFILE}/$@/cppcheck.err' || exit 1


cpplint:
	bash -c "${SETUP_SCRIPT}; \
		EXCEPTIONS=\$$(echo \$${CCWS_STATIC_DIR_EXCEPTIONS} | sed -e 's/:/ --exclude=/g'); \
		cpplint \
		\$${EXCEPTIONS} \
		--filter=-whitespace,-runtime/casting,-runtime/indentation_namespace,-readability/casting,-runtime/references,-readability/braces,-readability/namespace,-build/include_subdir,-build/header_guard,-build/include_order,-build/namespaces,-build/c++11,-readability/alt_tokens,-readability/todo,-build/include \
		--quiet --recursive '${WORKSPACE_SRC}'"


# internal target
static_checks_generic_dir_filter:
	mkdir -p ${WORKSPACE_DIR}/build/${BUILD_PROFILE}/${TARGET}
	echo -n "test -f ${WORKSPACE_DIR}/build/${BUILD_PROFILE}/${TARGET}/input && (cat ${WORKSPACE_DIR}/build/${BUILD_PROFILE}/${TARGET}/input" > ${WORKSPACE_DIR}/build/${BUILD_PROFILE}/${TARGET}/filter
	bash -c "${SETUP_SCRIPT}; \
		echo -n \$${CCWS_STATIC_DIR_EXCEPTIONS} | sed -e 's/:/ :/g' -e 's=:\([[:graph:]]*\)= | grep -v \"\1\" =g' >> ${WORKSPACE_DIR}/build/${BUILD_PROFILE}/${TARGET}/filter"
	echo -n " || true)" >> ${WORKSPACE_DIR}/build/${BUILD_PROFILE}/${TARGET}/filter


flawfinder:
	${MAKE} static_checks_generic_dir_filter TARGET=$@
	find "${WORKSPACE_SRC}" -type f \( -iname '*.cpp' -or -iname '*.h' \) > ${WORKSPACE_DIR}/build/${BUILD_PROFILE}/$@/input
	bash -c " \
		source ${WORKSPACE_DIR}/build/${BUILD_PROFILE}/$@/filter > ${WORKSPACE_DIR}/build/${BUILD_PROFILE}/$@/input.filtered; \
		cat ${WORKSPACE_DIR}/build/${BUILD_PROFILE}/$@/input.filtered | xargs --no-run-if-empty --max-procs=${JOBS} -I {} flawfinder --singleline --dataonly --quiet --minlevel=0 {}"


yamllint:
	${MAKE} static_checks_generic_dir_filter TARGET=$@
	find "${WORKSPACE_SRC}" -type f -iname '*.yaml' > ${WORKSPACE_DIR}/build/${BUILD_PROFILE}/$@/input
	bash -c "${SETUP_SCRIPT}; \
		source ${WORKSPACE_DIR}/build/${BUILD_PROFILE}/$@/filter > ${WORKSPACE_DIR}/build/${BUILD_PROFILE}/$@/input.filtered; \
		cat ${WORKSPACE_DIR}/build/${BUILD_PROFILE}/$@/input.filtered | xargs --max-procs=${JOBS} --no-run-if-empty -I {} \
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
		( find ${CCWS_DIR}/profiles/ -maxdepth 3 -type f \( -iname '*.sh' -or -iname '*.bash' \) \
			&& find ${CCWS_DIR}/scripts -type f \( -iname '*.sh' -or -iname '*.bash' \) \
			&& find ${WORKSPACE_DIR} -maxdepth 2 -type f \( -iname '*.sh' -or -iname '*.bash' \) \
			&& find "${WORKSPACE_SRC}" -iname '*.sh' -or -iname '*.bash' ) \
			> ${WORKSPACE_DIR}/build/${BUILD_PROFILE}/$@/input; \
		source ${WORKSPACE_DIR}/build/${BUILD_PROFILE}/$@/filter > ${WORKSPACE_DIR}/build/${BUILD_PROFILE}/$@/input.filtered; \
		cat ${WORKSPACE_DIR}/build/${BUILD_PROFILE}/$@/input.filtered | xargs --no-run-if-empty --max-procs=${JOBS} -I {} shellcheck -x \$${CCWS_SHELLCHECK_EXCEPTIONS} {}"


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
		'${WORKSPACE_SRC}'"

pylint:
	bash -c "${SETUP_SCRIPT}; \
		DIR_EXCEPTIONS=\$$(echo \$${CCWS_STATIC_DIR_EXCEPTIONS} | sed -e 's/^://' -e 's/:/,/g'); \
		pylint --rcfile \$${CCWS_BUILD_PROFILE_DIR}/pylintrc --jobs ${JOBS} --ignore-paths \"\$${DIR_EXCEPTIONS}\" '${WORKSPACE_SRC}'"

flake8:
	bash -c "${SETUP_SCRIPT}; \
		DIR_EXCEPTIONS=\$$(echo \$${CCWS_STATIC_DIR_EXCEPTIONS} | sed -e 's/^://' -e 's/:/,/g'); \
		flake8 --config \$${CCWS_BUILD_PROFILE_DIR}/flake8 --exclude \"\$${DIR_EXCEPTIONS}\" '${WORKSPACE_SRC}'"

mypy:
	${MAKE} static_checks_generic_dir_filter TARGET=$@
	bash -c "${SETUP_SCRIPT}; \
		DIR_EXCEPTIONS=\$$(echo \$${CCWS_STATIC_DIR_EXCEPTIONS} | sed -e 's/:/ --exclude /g' -e 's=${WORKSPACE_SRC}==g'); \
		find '${WORKSPACE_SRC}' -iname '*\.py' > ${WORKSPACE_DIR}/build/${BUILD_PROFILE}/$@/input; \
		source ${WORKSPACE_DIR}/build/${BUILD_PROFILE}/$@/filter > ${WORKSPACE_DIR}/build/${BUILD_PROFILE}/$@/input.filtered; \
		test -e ${WORKSPACE_DIR}/build/${BUILD_PROFILE}/$@/input.filtered -a ! -s ${WORKSPACE_DIR}/build/${BUILD_PROFILE}/$@/input.filtered \
			|| mypy --namespace-packages --explicit-package-bases --ignore-missing-imports \$${DIR_EXCEPTIONS} '${WORKSPACE_SRC}'"

