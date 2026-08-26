bp_codebase_memory_mcp_install_build: install_python3
	${PIPX_INSTALL} codebase-memory-mcp

bp_codebase_memory_mcp_build:
	bash -c "${SETUP_SCRIPT}; \
		CBM_CACHE_DIR=\$${CCWS_BUILD_DIR} \
		codebase-memory-mcp cli index_repository \
			--repo-path '${CCWS_SOURCE_DIR}' &"

bp_codebase_memory_mcp_kill:
	-pkill -f 'codebase-memory-mcp' || true
