APT_INSTALL?=sudo apt --yes --no-install-recommends install

wsinstall_ubuntu18:
	${APT_INSTALL} \
		python3-colcon-ros \
		python3-colcon-parallel-executor \
		python3-colcon-package-selection \
		python3-colcon-package-information
	${APT_INSTALL} python3-wstool
	${APT_INSTALL} build-essential
	${APT_INSTALL} clang-tools-10 clang-tidy-10
	${APT_INSTALL} wget

wsinstall_ubuntu20: wsinstall_ubuntu18

install:
	${MAKE} ${PROFILE}_install

download:
	bash -c "${SETUP_SCRIPT}; \
		cd \"\$${CCW_PROFILE_BUILD_DIR}\"; \
		wget --no-check-certificate ${FILES};"

# converts absolute symlinks to relative in a mounted sysroot
sysroot_fix_abs_symlinks:
	bash -c "${SETUP_SCRIPT}; \
		cd \"\$${CCW_SYSROOT}\"; \
		find ./usr -lname '/*' -printf 'sudo ln --relative --symbolic --force ./%l %p\n' | /bin/sh"
