QWEN_SRC_OUTER?=${CCWS_SOURCE_DIR}
QWEN_SRC_INNER?=/ccws/workspace/src
QWEN_CONTAINER?=asherikov/ccws_qwen_noble
SHOGGOTH_CFG_DIR?=${HOME}/.config/shoggoth

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

qwen_ccws: ssh_keygen_if_none
	mkdir -p "${CCWS_BUILD_DIR_BASE}"
	mkdir -p "${CCWS_INSTALL_DIR_BASE}"
	mkdir -p "${CCWS_ARTIFACTS_DIR_BASE}"
	#
	mkdir -p "${CCWS_SOURCE_DIR}/.ccws/qwen"
	mkdir -p "${CCWS_ARTIFACTS_DIR_BASE}/qwen/log"
	# shared apt cache
	mkdir -p "${CCWS_CACHE}/apt/cache"
	mkdir -p "${CCWS_CACHE}/apt/lists"
	# build dir is usable only from container anyway
	mkdir -p "${CCWS_CACHE}/qwen/build"
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
					&& echo "--volume=${SHOGGOTH_CFG_DIR}/tea-config.yml:/home/ccws/.config/tea/config.yml" \
					&& echo "--volume=${SHOGGOTH_CFG_DIR}/redmine-config.yml:/home/ccws/.redmine-cli.yaml")` \
			-v /tmp/.X11-unix:/tmp/.X11-unix \
			-v /dev/dri:/dev/dri \
			-v "$${SSH_AUTH_SOCK}:$${SSH_AUTH_SOCK}" \
			-v "${CCWS_CACHE}:/cache" \
			-v "${CCWS_CACHE}/apt/cache:/var/cache/apt" \
			-v "${CCWS_CACHE}/apt/lists:/var/lib/apt/lists/" \
			-v "${CCWS_DIR}/qwen/user:/home/ccws/.qwen/" \
			-v "${CCWS_DIR}/qwen/user:/root/.qwen/" \
			-v "${CCWS_DIR}/qwen/global:/etc/qwen-code/" \
			-v "${CCWS_DIR}/qwen/tmux.conf:/home/ccws/.tmux.conf" \
			-v "${CCWS_DIR}/skills/ccws:/ccws/skills/ccws" \
			-v ".gitignore:/ccws/.qwenignore:ro" \
			-v "${QWEN_SRC_OUTER}:${QWEN_SRC_INNER}" \
			-v "${QWEN_SRC_OUTER}/.ccws/qwen:/ccws/.qwen/" \
			-v "${CCWS_CACHE}/qwen/build:/ccws/workspace/build" \
			-v "${CCWS_INSTALL_DIR_BASE}:/ccws/workspace/install" \
			-v "${CCWS_ARTIFACTS_DIR_BASE}:/ccws/workspace/artifacts" \
			${QWEN_CONTAINER} \
		; kill $${SSH_AGENT_PID}
	# -v "${CCWS_SYSROOT_DIR_BASE}:/ccws/workspace/sysroot"
	# asherikov/ccws_qwen_noble

shoggoth:
	rm -rf "${CCWS_CACHE}/qwen/src"
	mkdir -p "${CCWS_CACHE}/qwen/src"
	${MAKE} qwen_ccws \
		CCWS_SOURCE_DIR="${CCWS_CACHE}/qwen/src" \
		QWEN_CONTAINER=docker-registry.shoggoth.local/slave_noble
