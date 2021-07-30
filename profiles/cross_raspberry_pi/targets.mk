# this way there is no need to specify profile explicitly -- it is implied by target names
SETUP_SCRIPT_cross_raspberry_pi=source ${WORKSPACE_DIR}/profiles/cross_raspberry_pi/setup.bash

cross_raspberry_pi_install: cross_raspberry_pi_clean cross_install_common_host_deps
	# gcc -> https://github.com/Pro/raspi-toolchain/
	# raspios -> http://downloads.raspberrypi.org/
	# the only reason we don't use lite image is that it doesn't have enough
	# space to install ROS dependencies, it is possible to resize it, but not
	# necessary for this demo
	${MAKE} wsclean_build PROFILE=cross_raspberry_pi
	${MAKE} download PROFILE=cross_raspberry_pi \
		FILES="https://github.com/Pro/raspi-toolchain/releases/download/v1.0.2/raspi-toolchain.tar.gz \
				http://downloads.raspberrypi.org/raspios_armhf/images/raspios_armhf-2021-05-28/2021-05-07-raspios-buster-armhf.zip"
	bash -c "${SETUP_SCRIPT_cross_raspberry_pi}; \
		cd \"\$${CCWS_PROFILE_BUILD_DIR}\"; \
		tar -xf raspi-toolchain.tar.gz; \
		unzip 2021-05-07-raspios-buster-armhf.zip; \
		mv cross-pi-gcc \"\$${CCWS_PROFILE_DIR}\"; \
		mv 2021-05-07-raspios-buster-armhf.img \"\$${CCWS_PROFILE_DIR}/system.img\""
	# 1. copy qemu in order to be able to do chroot
	# 2. remove some heavy packages to get free space for ROS dependencies
	${MAKE} cross_raspberry_pi_mount
	-bash -c "${SETUP_SCRIPT_cross_raspberry_pi}; \
		cd \"\$${CCWS_SYSROOT}\"; \
		sudo cp /usr/bin/qemu-arm-static ./usr/bin/; \
		sudo chroot ./ /bin/sh -c \
			'apt purge --yes chromium-browser libgl1-mesa-dri git realvnc-vnc-server; \
			apt clean; \
			apt update; \
			apt --yes upgrade; \
			apt clean'"
	${MAKE} cross_raspberry_pi_umount

cross_raspberry_pi_mount2: cross_raspberry_pi_umount
	sudo bash -c "${SETUP_SCRIPT_cross_raspberry_pi}; \
		cd \"\$${CCWS_PROFILE_DIR}\"; \
		CCWS_SYSROOT_DEVICE=\$$(${CROSS_SETUP_LOOP_DEV}); \
		mount \"\$${CCWS_SYSROOT_DEVICE}p2\" \"\$${CCWS_SYSROOT}\" "

cross_raspberry_pi_mount: cross_raspberry_pi_umount
	sudo bash -c "${SETUP_SCRIPT_cross_raspberry_pi}; \
		DEVICE=\$$(${CROSS_SETUP_LOOP_DEV}); \
		${MAKE} cross_sysroot_mount DEVICE=\$${DEVICE}p2; "

cross_raspberry_pi_umount:
	${MAKE} cross_umount PROFILE=cross_raspberry_pi

cross_raspberry_pi_purge: cross_raspberry_pi_umount
	sudo bash -c "${SETUP_SCRIPT_cross_raspberry_pi}; \
		rm -Rf \"\$${CCWS_PROFILE_DIR}/*.img; \
		rm -Rf \"\$${CCWS_PROFILE_DIR}/cross-pi-gcc"
