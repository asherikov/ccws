QWEN_SRC_OUTER?=${CCWS_SOURCE_DIR}
QWEN_SRC_INNER?=/ccws/workspace/src

qwen:
	mkdir -p "${CCWS_SOURCE_DIR}/.ccws/qwen"
	echo "*" > "${CCWS_SOURCE_DIR}/.ccws/qwen/.qwenignore"
	docker run --rm -ti \
		-v "${CCWS_SOURCE_DIR}:/ccws_src" \
		-v "${CCWS_SOURCE_DIR}/.ccws/qwen:/root/.qwen/" \
		ghcr.io/qwenlm/qwen-code /bin/bash -c "cd /ccws_src; qwen"

qwen_dir:
	mkdir -p ${DIR}/.ccws/qwen
	${MAKE} qwen_ccws QWEN_SRC_OUTER=${DIR} QWEN_SRC_INNER=${QWEN_SRC_INNER}/`basename ${DIR}`

qwen_ccws:
	mkdir -p "${CCWS_SOURCE_DIR}/.ccws/qwen"
	mkdir -p "${CCWS_ARTIFACTS_DIR_BASE}/qwen/log"
	# shared apt cache
	mkdir -p "${CCWS_CACHE}/apt/cache"
	mkdir -p "${CCWS_CACHE}/apt/lists"
	# build dir is usable only from container anyway
	mkdir -p "${CCWS_BUILD_DIR_BASE}/qwen"
	docker run --rm -ti \
		-e "CCWS_CACHE=/cache" \
		-v "${CCWS_CACHE}:/cache" \
		-v "${CCWS_CACHE}/apt/cache:/var/cache/apt" \
		-v "${CCWS_CACHE}/apt/lists:/var/lib/apt/lists/" \
		-v "${CCWS_DIR}/qwen:/root/.qwen/" \
		-v ".gitignore:/ccws/.qwenignore:ro" \
		-v "${QWEN_SRC_OUTER}:${QWEN_SRC_INNER}" \
		-v "${QWEN_SRC_OUTER}/.ccws/qwen:/ccws/.qwen/" \
		-v "${CCWS_BUILD_DIR_BASE}/qwen:/ccws/workspace/build" \
		-v "${CCWS_INSTALL_DIR_BASE}:/ccws/workspace/install" \
		-v "${CCWS_ARTIFACTS_DIR_BASE}:/ccws/workspace/artifacts" \
		asherikov/ccws_qwen_noble
	# -v "${CCWS_SYSROOT_DIR_BASE}:/ccws/workspace/sysroot"

