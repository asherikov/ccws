APT_INSTALL?=env DEBIAN_FRONTEND=noninteractive apt --yes --no-install-recommends install
PIP3_INSTALL?=python3 -m pip install

install_ccws_deps:
	# moreutils: ts (timestamping utility)
	sudo ${APT_INSTALL} wget gnupg2 moreutils ca-certificates git
	${MAKE} install_ros_key
	${MAKE} install_ccws_deps_${OS_DISTRO_BUILD}
	${MAKE} install_wshandler_${OS_DISTRO_BUILD}
	sudo ${APT_INSTALL} \
		python3-colcon-ros \
		python3-colcon-package-selection \
		python3-colcon-package-information \
		python3-colcon-bash \
		python3-colcon-cmake
	test -d /etc/ros/rosdep/sources.list.d/ || sudo rosdep init

install_ros_key:
	wget -qO- https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | sudo tee /etc/apt/trusted.gpg.d/ros.asc

install_ccws_build_deps: install_ccws_deps
	${APT_INSTALL} build-essential ccache proot gdb

install_python3:
	sudo ${APT_INSTALL} python3 python3-pip

install_ccws_deps_ros1:
	sh -c 'test -f /etc/apt/sources.list.d/ros-latest.list \
		|| test -f /etc/apt/sources.list.d/ros1-latest.list \
		|| (echo "deb http://packages.ros.org/ros/ubuntu ${OS_DISTRO_BUILD} main" | sudo tee /etc/apt/sources.list.d/ros-latest.list && apt update)'

install_ccws_deps_ros2:
	sh -c 'test -f /etc/apt/sources.list.d/ros2-latest.list \
		|| (echo "deb [arch=amd64,arm64] http://repo.ros2.org/ubuntu/main ${OS_DISTRO_BUILD} main" | sudo tee /etc/apt/sources.list.d/ros2-latest.list && apt update)'

install_wshandler_bionic:
	"${CCWS_DIR}/scripts/wshandler" -y yq --policy download install "${CCWS_DIR}/scripts/"

install_wshandler_focal: install_wshandler_bionic
	# passthrough

install_wshandler_%:
	sudo ${APT_INSTALL} gojq


#ubuntu18
install_ccws_deps_bionic: install_ccws_deps_ros1 install_ccws_deps_ros2
	sudo ${APT_INSTALL} \
		python-rosinstall-generator \
		python-rosdep \
		python-rospkg \
		python-empy

#ubuntu20
install_ccws_deps_focal: install_ccws_deps_ros1 install_ccws_deps_ros2
	sudo ${APT_INSTALL} \
		python3-rosinstall-generator \
		python3-rosdep \
		python3-rospkg

#ubuntu22
install_ccws_deps_jammy: install_ccws_deps_ros2
	sudo ${APT_INSTALL} \
		python3-rosinstall-generator \
		python3-rosdep \
		python3-rospkg

install_ccws_deps_noble: install_ccws_deps_jammy
	#ubuntu24


bp_install_build:
	echo "${CCWS_BUILD_PROFILES}" | sed -e 's/,/\n/g' | ${CCWS_XARGS} ${MAKE} bp_{}_install_build

bp_%_install_build: assert_BUILD_PROFILES_must_exist
	sudo ${MAKE} install_ccws_build_deps

ep_install:
	${MAKE} ep_${EXEC_PROFILE}_install

ep_%_install:
	${MAKE} dep_install

download:
	mkdir -p ${CCWS_CACHE}/${CCWS_DOWNLOAD_DIR}
	cd ${CCWS_CACHE}/${CCWS_DOWNLOAD_DIR}; wget --progress=dot:giga --timestamping --no-check-certificate ${FILES}
