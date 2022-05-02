nvidia_install_build_repos:
	${MAKE} download FILES="https://developer.download.nvidia.com/compute/cuda/repos/${DISTRO}/x86_64/${KEYRING_PKG}"
	${MAKE} download FILES="https://developer.download.nvidia.com/compute/cuda/repos/${DISTRO}/x86_64/${REPO_PKG}"
	sudo dpkg -i ${CCWS_CACHE}/${KEYRING_PKG} ${CCWS_CACHE}/${REPO_PKG}
