bp_codebase_memory_mcp_install_build: install_ccws_deps
	bash -c "${SETUP_SCRIPT}; \
		${MAKE} download CCWS_DOWNLOAD_DIR=codebase_memory_mcp \
			FILES=\$${CBM_DOWNLOAD_URL}/\$${CBM_ARCHIVE} || exit 1; \
		CBM_DLDIR=\$$(mktemp -d); \
		trap 'rm -rf \"\$${CBM_DLDIR}\"' EXIT; \
		tar --no-same-owner -xzf \"\$${CCWS_CACHE}/codebase_memory_mcp/\$${CBM_ARCHIVE}\" -C \"\$${CBM_DLDIR}\"; \
		mkdir -p '${CCWS_TOOLS_DIR}/bin'; \
		install -m 755 \"\$${CBM_DLDIR}/codebase-memory-mcp\" \"\$${CCWS_TOOLS_DIR}/bin\""

bp_codebase_memory_mcp_build:
	bash -c "${SETUP_SCRIPT}; \
		CBM_CACHE_DIR=\$${CCWS_BUILD_DIR} codebase-memory-mcp cli index_repository --repo-path '${CCWS_SOURCE_DIR}' &"

bp_codebase_memory_mcp_kill:
	-pkill -f 'codebase-memory-mcp' || true
