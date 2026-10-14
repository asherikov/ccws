CCWS_CLANG_BUILD_ANALYZER_VERSION?=1.6.0


bp_build_profiler_install_build: bp_clang_install_build
	${MAKE} bp_build_profiler_install_cba_$(shell uname -m)_${OS_DISTRO_BUILD}

# tools must not be built, only downloads are performed; prebuilt
# ClangBuildAnalyzer binaries are provided for x86_64 only
bp_build_profiler_install_cba_x86_64_jammy:
	${MAKE} download CCWS_DOWNLOAD_DIR=build_profiler \
		FILES=https://github.com/aras-p/ClangBuildAnalyzer/releases/download/v${CCWS_CLANG_BUILD_ANALYZER_VERSION}/ClangBuildAnalyzer-linux
	mkdir -p "${CCWS_TOOLS_DIR}/bin"
	install -m 755 \
		"${CCWS_CACHE}/build_profiler/ClangBuildAnalyzer-linux" \
		"${CCWS_TOOLS_DIR}/bin/ClangBuildAnalyzer"

bp_build_profiler_install_cba_x86_64_noble: bp_build_profiler_install_cba_x86_64_jammy
	#

bp_build_profiler_install_cba_x86_64_resolute: bp_build_profiler_install_cba_x86_64_jammy
	#

bp_build_profiler_install_cba_%:
	echo "CCWS: warning: no prebuilt ClangBuildAnalyzer binary for '$*', tools must not be built in this profile"
	echo "CCWS: warning: skipping ClangBuildAnalyzer installation, install it manually to enable the analysis"


bp_build_profiler_build: assert_BUILD_PROFILES_must_exist
	${MAKE} wswraptarget TARGET=private_build
	${MAKE} wswraptarget TARGET=bp_build_profiler_analyze

bp_build_profiler_analyze: assert_BUILD_PROFILES_must_exist
	bash -c "${SETUP_SCRIPT}; \
		mkdir -p '${CCWS_ARTIFACTS_DIR}'; \
		command -v ClangBuildAnalyzer > /dev/null 2>&1 || { \
			echo 'ClangBuildAnalyzer is not installed, run:'; \
			echo '    make bp_install_build BUILD_PROFILE=build_profiler'; \
			exit 1; \
		}; \
		ClangBuildAnalyzer --all '${CCWS_BUILD_DIR}' '${CCWS_BUILD_DIR}/.ccws/ClangBuildAnalyzer.bin'; \
		ClangBuildAnalyzer --analyze '${CCWS_BUILD_DIR}/.ccws/ClangBuildAnalyzer.bin' \
			| tee '${CCWS_ARTIFACTS_DIR}/clang_build_analyzer.txt'; \
		ccws_merge_time_traces.py '${CCWS_BUILD_DIR}' '${CCWS_ARTIFACTS_DIR}/time_traces.json' \
			|| echo 'CCWS: warning: failed to merge time traces'"
