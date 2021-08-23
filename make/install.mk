APT_INSTALL?=apt --yes --no-install-recommends install

install_build_deb_common:
	${APT_INSTALL} wget
	wget -qO - https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | apt-key add -
	sh -c 'test -f /etc/apt/sources.list.d/ros-latest.list \
		|| (echo "deb http://packages.ros.org/ros/ubuntu ${OS_DISTRO_BUILD} main" > /etc/apt/sources.list.d/ros-latest.list && apt update)'
	sh -c 'test -f /etc/apt/sources.list.d/ros2-latest.list \
		|| (echo "deb [arch=amd64,arm64] http://repo.ros2.org/ubuntu/main ${OS_DISTRO_BUILD} main" > /etc/apt/sources.list.d/ros2-latest.list && apt update)'
	${APT_INSTALL} \
		python3-colcon-ros \
		python3-colcon-package-selection \
		python3-colcon-package-information
	${APT_INSTALL} build-essential ccache proot

#ubuntu18
install_build_bionic: install_build_deb_common
	${APT_INSTALL} \
		python-rosinstall-generator \
		python-rosdep \
		python-rospkg \
		python-empy
	${APT_INSTALL} python-rosinstall python-wstool

#ubuntu20
install_build_focal: install_build_deb_common
	${APT_INSTALL} \
		python3-rosinstall-generator \
		python3-rosdep \
		python3-rospkg
	${APT_INSTALL} python3-rosinstall python3-wstool

install_build:
	sudo ${MAKE} install_build_${OS_DISTRO_BUILD}
	test -d /etc/ros/rosdep/sources.list.d/ || sudo rosdep init
	${MAKE} ${PROFILE}_install_build

%_install_build:
	# placeholder target, dont call this target manually
	test -d "${WORKSPACE_DIR}/profiles/$*"

install_host:
	${MAKE} ${PROFILE}_install_host

%_install_host:
	${MAKE} dep_install

download:
	bash -c "${SETUP_SCRIPT}; \
		mkdir -p \"\$${CCWS_BUILD_DIR}\"; \
		cd \"\$${CCWS_BUILD_DIR}\"; \
		wget --timestamping --no-check-certificate ${FILES};"
