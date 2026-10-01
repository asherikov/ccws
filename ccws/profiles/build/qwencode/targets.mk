bp_qwencode_install_build: bp_codebase_memory_mcp_install_build
	bash -c "wget -qO - https://deb.nodesource.com/setup_22.x | sudo bash"
	sudo apt update
	sudo ${APT_INSTALL} nodejs
	sudo ${APT_INSTALL} \
		man-db \
		curl \
		dnsutils \
		jq \
		bc \
		ripgrep \
		procps \
		psmisc \
		socat \
		rsync \
		lsof
	bash -c "${SETUP_SCRIPT}; npm install -g @qwen-code/qwen-code"

bp_qwencode_build: wsstatus
	${MAKE} BUILD_PROFILE=codebase_memory_mcp
	qwen
