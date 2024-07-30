APT_INSTALL?=env DEBIAN_FRONTEND=noninteractive apt --yes --no-install-recommends install
PIP3_INSTALL?=python3 -m pip install

install_ccws_deps:
	# moreutils: ts (timestamping utility)
	${APT_INSTALL} wget gnupg2 moreutils ca-certificates
	wget -qO- https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | sudo tee /etc/apt/trusted.gpg.d/ros.asc
	${APT_INSTALL} build-essential ccache proot
	${MAKE} install_ccws_deps_${OS_DISTRO_BUILD}
	command -v "wshandler" > /dev/null || test -x "${CCWS_DIR}/scripts/wshandler" || ${MAKE} wswraptarget TARGET="install_wshandler"
	${APT_INSTALL} \
		python3-colcon-ros \
		python3-colcon-package-selection \
		python3-colcon-package-information \
		python3-colcon-bash \
		python3-colcon-cmake
	test -d /etc/ros/rosdep/sources.list.d/ || rosdep init

install_python3:
	sudo ${APT_INSTALL} python3 python3-pip

install_ccws_deps_ros1:
	sh -c 'test -f /etc/apt/sources.list.d/ros-latest.list \
		|| (echo "deb http://packages.ros.org/ros/ubuntu ${OS_DISTRO_BUILD} main" > /etc/apt/sources.list.d/ros-latest.list && apt update)'

install_ccws_deps_ros2:
	sh -c 'test -f /etc/apt/sources.list.d/ros2-latest.list \
		|| (echo "deb [arch=amd64,arm64] http://repo.ros2.org/ubuntu/main ${OS_DISTRO_BUILD} main" > /etc/apt/sources.list.d/ros2-latest.list && apt update)'

install_wshandler:
	# ./scripts/wshandler/install.sh deps # requires snap
	${MAKE} download FILES="https://github.com/asherikov/wshandler/releases/download/0.1.0/wshandler-${CCWS_TRIPLE_ARCH}.AppImage"
	mv '${CCWS_CACHE}/wshandler-${CCWS_TRIPLE_ARCH}.AppImage' "${CCWS_DIR}/scripts/wshandler"
	chmod +x "${CCWS_DIR}/scripts/wshandler"


#ubuntu18
install_ccws_deps_bionic: install_ccws_deps_ros1 install_ccws_deps_ros2
	${APT_INSTALL} \
		python-rosinstall-generator \
		python-rosdep \
		python-rospkg \
		python-empy

#ubuntu20
install_ccws_deps_focal: install_ccws_deps_ros1 install_ccws_deps_ros2
	${APT_INSTALL} \
		python3-rosinstall-generator \
		python3-rosdep \
		python3-rospkg

#ubuntu22
install_ccws_deps_jammy: install_ccws_deps_ros2
	${APT_INSTALL} \
		python3-rosinstall-generator \
		python3-rosdep \
		python3-rospkg


bp_install_build:
	echo "CCWS/bp_install_build: ${BUILD_PROFILE}"
	${MAKE} bp_${BUILD_PROFILE}_install_build

bp_%_install_build: assert_BUILD_PROFILE_must_exist bp_common_install_build
	# placeholder target

ep_install:
	${MAKE} ep_${EXEC_PROFILE}_install

ep_%_install:
	${MAKE} dep_install

download:
	mkdir -p ${CCWS_CACHE}/${CCWS_DOWNLOAD_DIR}
	cd ${CCWS_CACHE}/${CCWS_DOWNLOAD_DIR}; wget --progress=dot:giga --timestamping --no-check-certificate ${FILES}
