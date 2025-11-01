qwen:
	mkdir -p "${CCWS_SOURCE_DIR}/.ccws/qwen"
	echo "*" > "${CCWS_SOURCE_DIR}/.ccws/qwen/.qwenignore"
	docker run --rm -ti \
		-v "${CCWS_SOURCE_DIR}:/ccws_src" \
		-v "${CCWS_SOURCE_DIR}/.ccws/qwen:/root/.qwen/" \
		ghcr.io/qwenlm/qwen-code /bin/bash -c "cd /ccws_src; qwen"

qwen_ccws:
	mkdir -p "${CCWS_SOURCE_DIR}/.ccws/qwen"
	docker run --rm -ti \
		-e "CCWS_CACHE=/cache" \
		-v "${CCWS_CACHE}:/cache" \
		-v ".gitignore:${WORKSPACE_DIR}/qwen/.qwenignore:ro" \
		-v "${CCWS_SOURCE_DIR}:/ccws/workspace/src" \
		-v "${CCWS_BUILD_DIR}:/ccws/workspace/build" \
		-v "${CCWS_INSTALL_DIR}:/ccws/workspace/install" \
		-v "${CCWS_ARTIFACTS_DIR}:/ccws/workspace/artifacts" \
		-v "${CCWS_SOURCE_DIR}/.ccws/qwen:/root/.qwen/" \
		asherikov/ccws_qwen_noble
