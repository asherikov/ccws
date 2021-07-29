# this way there is no need to specify profile explicitly -- it is implied by target names
SETUP_SCRIPT_cross_raspberry_pi=source ${WORKSPACE_DIR}/profiles/cross_raspberry_pi/setup.bash

cross_raspberry_pi_install: cross_raspberry_pi_clean
	${MAKE} wsprepare_build
	${APT_INSTALL} qemu-user-static
	# gcc -> https://github.com/Pro/raspi-toolchain/
	# raspios -> http://downloads.raspberrypi.org/
	# the only reason we don't use lite image is that it doesn't have enough
	# space to install ROS dependencies, it is possible to resize it, but not
	# necessary for this demo
	${MAKE} download PROFILE=cross_raspberry_pi \
		FILES="https://github.com/Pro/raspi-toolchain/releases/download/v1.0.2/raspi-toolchain.tar.gz \
			http://downloads.raspberrypi.org/raspios_armhf/images/raspios_armhf-2021-05-28/2021-05-07-raspios-buster-armhf.zip"
	bash -c "${SETUP_SCRIPT_cross_raspberry_pi}; \
		cd \"\$${CCW_PROFILE_BUILD_DIR}\"; \
		tar -xf raspi-toolchain.tar.gz; \
		unzip 2021-05-07-raspios-buster-armhf.zip; \
		mv cross-pi-gcc \"\$${CCW_PROFILE_DIR}\"; \
		mv 2021-05-07-raspios-buster-armhf.img \"\$${CCW_PROFILE_DIR}/system.img\""
	${MAKE} cross_raspberry_pi_mount
	# 1. copy qemu in order to be able to do chroot
	# 2. remove some heavy packages to get free space for ROS dependencies
	-bash -c "${SETUP_SCRIPT_cross_raspberry_pi}; \
		cd \"\$${CCW_SYSROOT}\"; \
		sudo cp /usr/bin/qemu-arm-static ./usr/bin/; \
		sudo chroot ./ /bin/sh -c \
			'apt purge --yes chromium-browser libgl1-mesa-dri git realvnc-vnc-server; \
			apt clean; \
			apt update; \
			apt --yes upgrade; \
			apt clean'"
	${MAKE} cross_raspberry_pi_umount

cross_raspberry_pi_clean:
	bash -c "${SETUP_SCRIPT_cross_raspberry_pi}; \
		rm -Rf \"\$${CCW_PROFILE_BUILD_DIR}\""

cross_raspberry_pi_mount: cross_raspberry_pi_umount
	sudo bash -c "${SETUP_SCRIPT_cross_raspberry_pi}; \
		cd \"\$${CCW_PROFILE_DIR}\"; \
		CCW_SYSROOT_DEVICE=\$$(sudo losetup -PL --find --show ./system.img); \
		mount \"\$${CCW_SYSROOT_DEVICE}p2\" \"\$${CCW_SYSROOT}\" "

cross_raspberry_pi_umount:
	sudo bash -c "${SETUP_SCRIPT_cross_raspberry_pi}; \
		rm -Rf /opt/cross-pi-gcc || true; \
		umount --recursive \"\$${CCW_SYSROOT}\" || true"

cross_raspberry_pi_purge: cross_raspberry_pi_umount
	sudo bash -c "${SETUP_SCRIPT_cross_raspberry_pi}; \
		rm -Rf \"\$${CCW_PROFILE_DIR}/*.img; \
		rm -Rf \"\$${CCW_PROFILE_DIR}/cross-pi-gcc"
