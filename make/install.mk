APT_INSTALL?=env DEBIAN_FRONTEND=noninteractive apt --yes --no-install-recommends install

install_ccws_deps:
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
	${MAKE} install_ccws_deps_${OS_DISTRO_BUILD}
	test -d /etc/ros/rosdep/sources.list.d/ || rosdep init

#ubuntu18
install_ccws_deps_bionic:
	${APT_INSTALL} \
		python-rosinstall-generator \
		python-rosdep \
		python-rospkg \
		python-empy
	${APT_INSTALL} python-rosinstall python-wstool

#ubuntu20
install_ccws_deps_focal:
	${APT_INSTALL} \
		python3-rosinstall-generator \
		python3-rosdep \
		python3-rospkg
	${APT_INSTALL} python3-rosinstall python3-wstool


bp_install_build:
	${MAKE} bp_${BUILD_PROFILE}_install_build

bp_%_install_build: assert_BUILD_PROFILE_must_exist bp_common_install_build
	# placeholder target

bp_install_host:
	${MAKE} bp_${BUILD_PROFILE}_install_host

bp_%_install_host:
	${MAKE} dep_install

ep_install:
	${MAKE} ep_${EXEC_PROFILE}_install

ep_%_install:
	${MAKE} dep_install

download:
	cd ${WORKSPACE_DIR}/cache; wget --progress=dot:giga --timestamping --no-check-certificate ${FILES}
