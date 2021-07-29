APT_INSTALL?=sudo apt --yes --no-install-recommends install

wsinstall_deb_common:
	${APT_INSTALL} \
		python3-colcon-ros \
		python3-colcon-parallel-executor \
		python3-colcon-package-selection \
		python3-colcon-package-information
	${APT_INSTALL} python3-wstool
	${APT_INSTALL} build-essential
	${APT_INSTALL} wget

wsinstall_ubuntu18: wsinstall_deb_common
	${APT_INSTALL} clang-tools-10 clang-tidy-10
	${APT_INSTALL} python-rosdep

wsinstall_ubuntu20: wsinstall_deb_common
	${APT_INSTALL} clang-tools-10 clang-tidy-10
	${APT_INSTALL} python3-rosdep

install:
	${MAKE} ${PROFILE}_install

download:
	bash -c "${SETUP_SCRIPT}; \
		cd \"\$${CCWS_PROFILE_BUILD_DIR}\"; \
		wget --no-check-certificate ${FILES};"
