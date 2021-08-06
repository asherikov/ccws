APT_INSTALL?=sudo apt --yes --no-install-recommends install

wsinstall_deb_common:
	${APT_INSTALL} \
		python3-colcon-ros \
		python3-colcon-parallel-executor \
		python3-colcon-package-selection \
		python3-colcon-package-information
	${APT_INSTALL} python3-wstool
	${APT_INSTALL} build-essential ccache doxygen
	${APT_INSTALL} wget

#ubuntu18
wsinstall_bionic: wsinstall_deb_common
	${APT_INSTALL} \
		python-rosinstall-generator \
		python-rosdep \
		python-rospkg

#ubuntu20
wsinstall_focal: wsinstall_deb_common
	${APT_INSTALL} \
		python3-rosinstall-generator \
		python3-rosdep \
		python3-rospkg

install:
	${MAKE} wsinstall_${OS_DISTRO}
	${MAKE} ${PROFILE}_install

%_install:
	# placeholder target, dont call this target manually
	test -d "${WORKSPACE_DIR}/profiles/$*"

download: wsprepare_build
	bash -c "${SETUP_SCRIPT}; \
		cd \"\$${CCWS_BUILD_DIR}\"; \
		wget --timestamping --no-check-certificate ${FILES};"
