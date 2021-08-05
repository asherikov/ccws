APT_INSTALL?=sudo apt --yes --no-install-recommends install

wsinstall_deb_common:
	${APT_INSTALL} \
		python3-colcon-ros \
		python3-colcon-parallel-executor \
		python3-colcon-package-selection \
		python3-colcon-package-information
	${APT_INSTALL} python3-wstool
	${APT_INSTALL} build-essential
	${APT_INSTALL} wget curl

#ubuntu18
wsinstall_bionic: wsinstall_deb_common
	${APT_INSTALL} \
		clang-tools-10 clang-tidy-10 \
		python-rosinstall-generator \
		python-rosdep \
		python-rospkg \

#ubuntu20
wsinstall_focal: wsinstall_deb_common
	${APT_INSTALL} \
		clang-tools-10 clang-tidy-10 \
		python3-rosinstall-generator \
		python3-rosdep \
		python3-rospkg

install:
	${MAKE} ${PROFILE}_install

download: wsprepare_build
	bash -c "${SETUP_SCRIPT}; \
		cd \"\$${CCWS_BUILD_DIR}\"; \
		wget --timestamping --no-check-certificate ${FILES};"
