bp_static_checks_install_build: install_ccws_deps
	sudo ${APT_INSTALL} \
		cppcheck \
		flawfinder \
		yamllint \
		shellcheck
	${MAKE} bp_static_checks_install_build_${OS_DISTRO_BUILD}
	${MAKE} bp_static_checks_install_build_python_${OS_DISTRO_BUILD}

#ubuntu18
bp_static_checks_install_build_bionic:
	sudo ${APT_INSTALL} python-catkin-lint

#ubuntu20
bp_static_checks_install_build_focal:
	sudo ${APT_INSTALL} python3-catkin-lint

#ubuntu22
bp_static_checks_install_build_jammy: install_python3
	${PIPX_INSTALL} catkin-lint

#ubuntu24
bp_static_checks_install_build_noble: install_python3
	sudo ${APT_INSTALL} catkin-lint

bp_static_checks_install_build_python_%: install_python3
	${PIPX_INSTALL} pylint
	${PIPX_INSTALL} flake8
	#${PIP3_INSTALL} mypy
	## required by mypy
	#${PIP3_INSTALL} types-PyYAML

bp_static_checks_install_build_python_noble: install_python3
	sudo ${APT_INSTALL} pylint python3-typeshed
	# mypy
	# apt package is broken in github build container
	${PIPX_INSTALL} flake8


bp_static_checks_build_common:
	${MAKE} cppcheck
	${MAKE} yamllint
	#${MAKE} cpplint
	${MAKE} shellcheck
	# false positives
	-${MAKE} flawfinder
	${MAKE} bp_static_checks_build_python

#ubuntu18
bp_static_checks_build_bionic:
	${MAKE} catkin_lint

#ubuntu20
bp_static_checks_build_focal:
	${MAKE} catkin_lint

bp_static_checks_build_%:
	# do nothing

bp_static_checks_build: bp_static_checks_build_common
	${MAKE} bp_static_checks_build_${OS_DISTRO_BUILD}

bp_static_checks_build_python:
	${MAKE} pylint
	${MAKE} flake8
	#${MAKE} mypy


cppcheck:
	# --inconclusive -- can be used to catch some extra issues
	# --error-exitcode=1 -- fails with no errors printed
	#
	# Header files are specified explicitly since cppcheck ignores them if
	# directory is provided as an input, the correct way is probably to specify
	# header paths with `-I` flags but that is not trivial in a workspace,
	# might require parsing compilation commands from cmake.
	${MAKE} static_checks_generic_dir_filter TARGET=$@
	find "${CCWS_SOURCE_DIR}" -type f -iname '*.hpp' -or -iname "*.cpp" -or -iname "*.h" > ${CCWS_BUILD_DIR}/$@/input
	rm -f '${CCWS_BUILD_DIR}/$@/cppcheck.err'
	bash -c "${SETUP_SCRIPT}; \
		source ${CCWS_BUILD_DIR}/$@/filter > ${CCWS_BUILD_DIR}/$@/input.filtered; \
		cat ${CCWS_BUILD_DIR}/$@/input.filtered | xargs --max-procs=${JOBS} --no-run-if-empty -I {} \
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
			| tee --append '${CCWS_BUILD_DIR}/$@/cppcheck.err' "
	test ! -s '${CCWS_BUILD_DIR}/$@/cppcheck.err' || exit 1


cpplint:
	bash -c "${SETUP_SCRIPT}; \
		EXCEPTIONS=\$$(echo \$${CCWS_STATIC_DIR_EXCEPTIONS} | sed -e 's/:/ --exclude=/g'); \
		cpplint \
		\$${EXCEPTIONS} \
		--filter=-whitespace,-runtime/casting,-runtime/indentation_namespace,-readability/casting,-runtime/references,-readability/braces,-readability/namespace,-build/include_subdir,-build/header_guard,-build/include_order,-build/namespaces,-build/c++11,-readability/alt_tokens,-readability/todo,-build/include \
		--quiet --recursive '${CCWS_SOURCE_DIR}'"


# internal target
static_checks_generic_dir_filter:
	mkdir -p ${CCWS_BUILD_DIR}/${TARGET}
	echo -n "test -f ${CCWS_BUILD_DIR}/${TARGET}/input && (cat ${CCWS_BUILD_DIR}/${TARGET}/input" > ${CCWS_BUILD_DIR}/${TARGET}/filter
	bash -c "${SETUP_SCRIPT}; \
		echo -n \$${CCWS_STATIC_DIR_EXCEPTIONS} | sed -e 's/:/ :/g' -e 's=:\([[:graph:]]*\)= | grep -v \"\1\" =g' >> ${CCWS_BUILD_DIR}/${TARGET}/filter"
	echo -n " || true)" >> ${CCWS_BUILD_DIR}/${TARGET}/filter


flawfinder:
	${MAKE} static_checks_generic_dir_filter TARGET=$@
	find "${CCWS_SOURCE_DIR}" -type f \( -iname '*.cpp' -or -iname '*.h' \) > ${CCWS_BUILD_DIR}/$@/input
	bash -c " \
		source ${CCWS_BUILD_DIR}/$@/filter > ${CCWS_BUILD_DIR}/$@/input.filtered; \
		cat ${CCWS_BUILD_DIR}/$@/input.filtered | xargs --no-run-if-empty --max-procs=${JOBS} -I {} flawfinder --singleline --dataonly --quiet --minlevel=0 {}"


yamllint:
	${MAKE} static_checks_generic_dir_filter TARGET=$@
	find "${CCWS_SOURCE_DIR}" -type f -iname '*.yaml' > ${CCWS_BUILD_DIR}/$@/input
	bash -c "${SETUP_SCRIPT}; \
		source ${CCWS_BUILD_DIR}/$@/filter > ${CCWS_BUILD_DIR}/$@/input.filtered; \
		cat ${CCWS_BUILD_DIR}/$@/input.filtered | xargs --max-procs=${JOBS} --no-run-if-empty -I {} \
		env LC_ALL=C.UTF-8 yamllint -d \"{extends: default, \
                      rules: { \
                        colons: {max-spaces-before: 0, max-spaces-after: -1}, \
                        commas: disable, \
                        comments: {require-starting-space: false, min-spaces-from-content: 0}, \
                        document-start: disable, \
                        indentation: disable, \
                        line-length: disable, \
                        trailing-spaces: disable, \
                        new-line-at-end-of-file: disable, \
                        comments-indentation: disable, \
                        empty-lines: {max: 5, max-end: 1}}}\" {}"


shellcheck:
	${MAKE} static_checks_generic_dir_filter TARGET=$@
	bash -c "${SETUP_SCRIPT}; \
		( find ${CCWS_DIR}/profiles/ -maxdepth 3 -type f \( -iname '*.sh' -or -iname '*.bash' \) \
			&& find ${CCWS_TOOLS_DIR}/bin/ -type f \( -iname '*.sh' -or -iname '*.bash' \) \
			&& echo "${CCWS_ROOT}/setup.bash" \
			&& find "${CCWS_SOURCE_DIR}" -iname '*.sh' -or -iname '*.bash' ) \
			> ${CCWS_BUILD_DIR}/$@/input; \
		source ${CCWS_BUILD_DIR}/$@/filter > ${CCWS_BUILD_DIR}/$@/input.filtered; \
		cat ${CCWS_BUILD_DIR}/$@/input.filtered | xargs --no-run-if-empty --max-procs=${JOBS} -I {} shellcheck -x \$${CCWS_SHELLCHECK_EXCEPTIONS} {}"


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
		'${CCWS_SOURCE_DIR}'"

pylint:
	bash -c "${SETUP_SCRIPT}; \
		DIR_EXCEPTIONS=\$$(echo \$${CCWS_STATIC_DIR_EXCEPTIONS} | sed -e 's/^://' -e 's/:/,/g'); \
		pylint --rcfile \$${CCWS_PRIMARY_BUILD_PROFILE_DIR}/pylintrc --jobs ${JOBS} --ignore-paths \"\$${DIR_EXCEPTIONS}\" '${CCWS_SOURCE_DIR}'"

flake8:
	bash -c "${SETUP_SCRIPT}; \
		DIR_EXCEPTIONS=\$$(echo \$${CCWS_STATIC_DIR_EXCEPTIONS} | sed -e 's/^://' -e 's/:/,/g'); \
		flake8 --config \$${CCWS_PRIMARY_BUILD_PROFILE_DIR}/flake8 --exclude \"\$${DIR_EXCEPTIONS},site-packages\" '${CCWS_SOURCE_DIR}'"

mypy:
	${MAKE} static_checks_generic_dir_filter TARGET=$@
	bash -c "${SETUP_SCRIPT}; \
		DIR_EXCEPTIONS=\$$(echo \$${CCWS_STATIC_DIR_EXCEPTIONS} | sed -e 's/:/ --exclude /g' -e 's=${CCWS_SOURCE_DIR}==g'); \
		find '${CCWS_SOURCE_DIR}' -iname '*\.py' > ${CCWS_BUILD_DIR}/$@/input; \
		source ${CCWS_BUILD_DIR}/$@/filter > ${CCWS_BUILD_DIR}/$@/input.filtered; \
		test -e ${CCWS_BUILD_DIR}/$@/input.filtered -a ! -s ${CCWS_BUILD_DIR}/$@/input.filtered \
			|| mypy --disable-error-code attr-defined --namespace-packages --explicit-package-bases --ignore-missing-imports \$${DIR_EXCEPTIONS} '${CCWS_SOURCE_DIR}'"

