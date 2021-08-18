APT_INSTALL?=apt --yes --no-install-recommends install

host_install_deb_common:
	${APT_INSTALL} \
		python3-colcon-ros \
		python3-colcon-parallel-executor \
		python3-colcon-package-selection \
		python3-colcon-package-information
	${APT_INSTALL} python3-wstool
	${APT_INSTALL} build-essential ccache proot
	${APT_INSTALL} wget

#ubuntu18
host_install_bionic: host_install_deb_common
	${APT_INSTALL} \
		python-rosinstall-generator \
		python-rosdep \
		python-rospkg

#ubuntu20
host_install_focal: host_install_deb_common
	${APT_INSTALL} \
		python3-rosinstall-generator \
		python3-rosdep \
		python3-rospkg

host_install:
	sudo ${MAKE} host_install_${OS_DISTRO}
	${MAKE} ${PROFILE}_host_install

%_host_install:
	# placeholder target, dont call this target manually
	test -d "${WORKSPACE_DIR}/profiles/$*"

target_install: assert_PKG_arg_must_be_specified
	${MAKE} ${PROFILE}_target_install

%_target_install:
	${MAKE} rosdep_install

download: wsprepare_build
	bash -c "${SETUP_SCRIPT}; \
		cd \"\$${CCWS_BUILD_DIR}\"; \
		wget --timestamping --no-check-certificate ${FILES};"
