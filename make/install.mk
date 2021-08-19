APT_INSTALL?=apt --yes --no-install-recommends install

host_install_deb_common:
	${APT_INSTALL} wget
	wget -qO - https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | apt-key add -
	sh -c 'test -f /etc/apt/sources.list.d/ros-latest.list \
		|| (echo "deb http://packages.ros.org/ros/ubuntu ${OS_DISTRO} main" > /etc/apt/sources.list.d/ros-latest.list && apt update)'
	sh -c 'test -f /etc/apt/sources.list.d/ros2-latest.list \
		|| (echo "deb [arch=amd64,arm64] http://repo.ros2.org/ubuntu/main ${OS_DISTRO} main" > /etc/apt/sources.list.d/ros2-latest.list && apt update)'
	${APT_INSTALL} \
		python3-colcon-ros \
		python3-colcon-package-selection \
		python3-colcon-package-information
	${APT_INSTALL} build-essential ccache proot

#ubuntu18
host_install_bionic: host_install_deb_common
	${APT_INSTALL} \
		python-rosinstall-generator \
		python-rosdep \
		python-rospkg
	${APT_INSTALL} python-rosinstall python-wstool

#ubuntu20
host_install_focal: host_install_deb_common
	${APT_INSTALL} \
		python3-rosinstall
		python3-rosinstall-generator \
		python3-rosdep \
		python3-rospkg
	${APT_INSTALL} python3-rosinstall python3-wstool

host_install:
	sudo ${MAKE} host_install_${OS_DISTRO}
	sh -c 'test -d /etc/ros/rosdep/sources.list.d/ || sudo rosdep init'
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
