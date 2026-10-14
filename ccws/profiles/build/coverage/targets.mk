bp_coverage_install_build: install_python3
	${PIPX_INSTALL} gcovr

# textual summary is printed to stdout, machine readable results are stored in
# the artifacts directory:
#   <pkg>.info (lcov, e.g. codecov, coveralls)
#   <pkg>.cobertura.xml (cobertura, e.g. gitlab)
# when CDash is configured (CDASH_URL / CDASH_PROJECT), the lcov data is also
# converted to CDash Coverage.xml in the per-package artifacts directory,
# cdash_submit picks it up together with test results
bp_coverage_process_pkg: assert_PKG_arg_must_be_specified
	@mkdir -p ${CCWS_ARTIFACTS_DIR}/coverage
	@echo '${PKG}' | sed 's/ /\n/g' | ${CCWS_XARGS} bash -c "\
		if [ -d '${CCWS_BUILD_DIR}/{}' ]; then \
			gcovr \
				--root '${CCWS_SOURCE_DIR}/{}' \
				$(foreach CCWS_COVERAGE_EXCLUDE_PATTERN,${CCWS_COVERAGE_EXCLUDE},--exclude ${CCWS_COVERAGE_EXCLUDE_PATTERN}) \
				--txt=- \
				--lcov='${CCWS_ARTIFACTS_DIR}/coverage/{}.info' \
				--cobertura='${CCWS_ARTIFACTS_DIR}/coverage/{}.cobertura.xml' \
				'${CCWS_BUILD_DIR}/{}'; \
			test -z '${CDASH_URL}${CDASH_PROJECT}' || ${CCWS_TOOLS_DIR}/bin/ccws_lcov2cdash.py \
				'${CCWS_ARTIFACTS_DIR}/coverage/{}.info' \
				'${CCWS_ARTIFACTS_DIR}/{}' \
				--strip-prefix '${CCWS_SOURCE_DIR}/'; \
		else \
			echo 'CCWS: no coverage data for {}, was it built with the coverage profile?'; \
		fi"

bp_coverage_process_ws:
	@mkdir -p ${CCWS_ARTIFACTS_DIR}/coverage
	@bash -c "${SETUP_SCRIPT}; \
		if [ -d '${CCWS_BUILD_DIR}' ]; then \
			EXCLUDE_ARGS=; \
			for EXCLUDE_PATTERN in \$${CCWS_COVERAGE_EXCLUDE}; do \
				EXCLUDE_ARGS=\"\$${EXCLUDE_ARGS} --exclude \$${EXCLUDE_PATTERN}\"; \
			done; \
			gcovr \
				--root '${CCWS_SOURCE_DIR}' \
				\$${EXCLUDE_ARGS} \
				--txt=- \
				--lcov='${CCWS_ARTIFACTS_DIR}/coverage/coverage.info' \
				--cobertura='${CCWS_ARTIFACTS_DIR}/coverage/cobertura.xml' \
				'${CCWS_BUILD_DIR}'; \
		else \
			echo 'CCWS: ${CCWS_BUILD_DIR} does not exist, was anything built with the coverage profile?'; \
		fi"
