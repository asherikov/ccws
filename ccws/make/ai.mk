CCWS_AI?=qwen
CCWS_AI_SRC_OUTER?=${CCWS_SOURCE_DIR}
CCWS_AI_SRC_INNER?=/ccws/workspace/src

CCWS_AI_CONTAINER?=asherikov/ccws_${CCWS_AI}_noble

SHOGGOTH_CFG_DIR?=${HOME}/.config/shoggoth

ai_common_setup: ssh_keygen_if_none
	mkdir -p "${CCWS_BUILD_DIR_BASE}"
	mkdir -p "${CCWS_INSTALL_DIR_BASE}"
	mkdir -p "${CCWS_ARTIFACTS_DIR_BASE}"
	# shared apt cache
	mkdir -p "${CCWS_CACHE}/apt/cache"
	mkdir -p "${CCWS_CACHE}/apt/lists"
	#
	mkdir -p "${CCWS_SOURCE_DIR}/.ccws/${CCWS_AI}"
	mkdir -p "${CCWS_ARTIFACTS_DIR_BASE}/${CCWS_AI}/log"
	# build dir is usable only from container anyway
	mkdir -p "${CCWS_CACHE}/${CCWS_AI}/build"

qwen:
	mkdir -p "${CCWS_SOURCE_DIR}/.ccws/qwen"
	echo "*" > "${CCWS_SOURCE_DIR}/.ccws/qwen/.qwenignore"
	docker run --rm -ti \
		-v "${CCWS_SOURCE_DIR}:/ccws_src" \
		-v "${CCWS_SOURCE_DIR}/.ccws/qwen:/root/.qwen/" \
		ghcr.io/qwenlm/qwen-code /bin/bash -c "cd /ccws_src; qwen"

qwen_dir:
	mkdir -p ${DIR}/.ccws/qwen
	${MAKE} qwen_ccws CCWS_AI_SRC_OUTER=${DIR} CCWS_AI_SRC_INNER=${CCWS_AI_SRC_INNER}/`basename ${DIR}`

qwen_ccws:
	${MAKE} ai_common_setup CCWS_AI=qwen
	#--user `id -u`:`id -g` # interferes with sudo
	#--ipc host # no constraints on shared memory
	eval `ssh-agent` \
		&& ssh-add "${CCWS_SSH_KEY}" \
		&& docker run --rm -ti \
			--ipc host \
			--net host \
			`test ! -d "${SHOGGOTH_CFG_DIR}" || echo "--env-file=${SHOGGOTH_CFG_DIR}/env"` \
			-e "CCWS_CACHE=/cache" \
			-e "DISPLAY=${DISPLAY}" \
			-e "SSH_AUTH_SOCK=$${SSH_AUTH_SOCK}" \
			`test ! -d "${SHOGGOTH_CFG_DIR}" \
				|| (echo "--volume=${SHOGGOTH_CFG_DIR}/apt-cache.conf:/etc/apt/apt.conf.d/00-shoggoth-apt-cache" \
					&& echo "--volume=${SHOGGOTH_CFG_DIR}/tea-config.yml:/home/ccws/.config/tea/config.yml")` \
			-v /tmp/.X11-unix:/tmp/.X11-unix \
			-v /dev/dri:/dev/dri \
			-v "$${SSH_AUTH_SOCK}:$${SSH_AUTH_SOCK}" \
			-v "${CCWS_CACHE}:/cache" \
			-v "${CCWS_CACHE}/apt/cache:/var/cache/apt" \
			-v "${CCWS_CACHE}/apt/lists:/var/lib/apt/lists/" \
			-v "${CCWS_DIR}/qwen/user:/home/ccws/.qwen/" \
			-v "${CCWS_DIR}/qwen/user:/root/.qwen/" \
			-v "${CCWS_DIR}/qwen/global:/etc/qwen-code/" \
			-v "${CCWS_DIR}/examples/tmux.conf:/home/ccws/.tmux.conf" \
			-v "${HOME}/.config/nvim/init.vim:/home/ccws/.config/nvim/init.vim" \
			-v "${HOME}/.config/nvim/init.vim:/root/.config/nvim/init.vim" \
			-v "${CCWS_DIR}/skills/ccws:/ccws/skills/ccws" \
			-v ".gitignore:/ccws/.qwenignore:ro" \
			-v "${CCWS_AI_SRC_OUTER}:${CCWS_AI_SRC_INNER}" \
			-v "${CCWS_AI_SRC_OUTER}/.ccws/qwen:/ccws/.qwen/" \
			-v "${CCWS_CACHE}/ai/build:/ccws/workspace/build" \
			-v "${CCWS_INSTALL_DIR_BASE}:/ccws/workspace/install" \
			-v "${CCWS_ARTIFACTS_DIR_BASE}:/ccws/workspace/artifacts" \
			${CCWS_AI_CONTAINER} \
		; kill $${SSH_AGENT_PID}
	# -v "${CCWS_SYSROOT_DIR_BASE}:/ccws/workspace/sysroot"
	# asherikov/ccws_qwen_noble

opencode:
	mkdir -p "${CCWS_SOURCE_DIR}/.ccws/opencode"
	echo "*" > "${CCWS_SOURCE_DIR}/.ccws/opencode/.qwenignore"
	docker run --rm -ti \
		-v "${CCWS_SOURCE_DIR}:/ccws_src" \
		-v "${CCWS_SOURCE_DIR}/.ccws/opencode:/root/.opencode/" \
		${CCWS_AI_CONTAINER} /bin/bash -c "cd /ccws_src; opencode"

opencode_dir:
	mkdir -p ${DIR}/.ccws/opencode
	${MAKE} opencode_ccws CCWS_AI_SRC_OUTER=${DIR} CCWS_AI_SRC_INNER=${CCWS_AI_SRC_INNER}/`basename ${DIR}`

opencode_ccws:
	${MAKE} ai_common_setup CCWS_AI=opencode
	eval `ssh-agent` \
		&& ssh-add "${CCWS_SSH_KEY}" \
		&& docker run --rm -ti \
			--ipc host \
			--net host \
			`test ! -d "${SHOGGOTH_CFG_DIR}" || echo "--env-file=${SHOGGOTH_CFG_DIR}/env"` \
			-e "CCWS_CACHE=/cache" \
			-e "DISPLAY=${DISPLAY}" \
			-e "SSH_AUTH_SOCK=$${SSH_AUTH_SOCK}" \
			-e "OPENCODE_CONFIG_DIR=/ccws/.ccws/opencode/" \
			-e "OPENCODE_DISABLE_LSP_DOWNLOAD=true" \
			`test ! -d "${SHOGGOTH_CFG_DIR}" \
				|| (echo "--volume=${SHOGGOTH_CFG_DIR}/apt-cache.conf:/etc/apt/apt.conf.d/00-shoggoth-apt-cache" \
					&& echo "--volume=${SHOGGOTH_CFG_DIR}/tea-config.yml:/home/ccws/.config/tea/config.yml")` \
			-v /tmp/.X11-unix:/tmp/.X11-unix \
			-v /dev/dri:/dev/dri \
			-v "$${SSH_AUTH_SOCK}:$${SSH_AUTH_SOCK}" \
			-v "${CCWS_CACHE}:/cache" \
			-v "${CCWS_CACHE}/apt/cache:/var/cache/apt" \
			-v "${CCWS_CACHE}/apt/lists:/var/lib/apt/lists/" \
			-v "${CCWS_DIR}/opencode/user:/home/ccws/.config/opencode/" \
			-v "${CCWS_DIR}/opencode/user:/root/.config/opencode/" \
			-v "${CCWS_DIR}/examples/tmux.conf:/home/ccws/.tmux.conf" \
			-v "${CCWS_DIR}/skills/ccws:/ccws/skills/ccws" \
			-v ".gitignore:/ccws/.qwenignore:ro" \
			-v "${CCWS_AI_SRC_OUTER}:${CCWS_AI_SRC_INNER}" \
			-v "${CCWS_AI_SRC_OUTER}/.ccws/opencode:/ccws/.ccws/opencode/" \
			-v "${CCWS_CACHE}/ai/build:/ccws/workspace/build" \
			-v "${CCWS_INSTALL_DIR_BASE}:/ccws/workspace/install" \
			-v "${CCWS_ARTIFACTS_DIR_BASE}:/ccws/workspace/artifacts" \
			asherikov/ccws_opencode_noble \
		; kill $${SSH_AGENT_PID}

shoggoth:
	rm -rf "${CCWS_CACHE}/shoggoth/src"
	mkdir -p "${CCWS_CACHE}/shoggoth/src"
	${MAKE} ${CCWS_AI}_ccws \
		CCWS_SOURCE_DIR="${CCWS_CACHE}/shoggoth/src" \
		CCWS_AI_CONTAINER=docker-registry.shoggoth.local/slave_noble

shoggoth_dir:
	${MAKE} ${CCWS_AI}_dir \
		CCWS_AI_CONTAINER=docker-registry.shoggoth.local/slave_noble
