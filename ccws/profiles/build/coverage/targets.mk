bp_coverage_install_build:
	${PIPX_INSTALL} gcovr

# textual summary is printed to stdout, machine readable results are stored in
# the artifacts directory:
#   <pkg>.info (lcov, e.g. codecov, coveralls)
#   <pkg>.cobertura.xml (cobertura, e.g. gitlab)
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
