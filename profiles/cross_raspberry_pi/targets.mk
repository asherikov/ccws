SETUP_SCRIPT_cross_raspberry_pi=source ${WORKSPACE_DIR}/profiles/cross_raspberry_pi/setup.bash

cross_raspberry_pi_install: cross_raspberry_pi_clean
	${APT_INSTALL} qemu-user-static
	# gcc -> https://github.com/Pro/raspi-toolchain/
	# raspios -> http://downloads.raspberrypi.org/raspios_lite_armhf/images/raspios_lite_armhf-2021-05-28/
	#            http://downloads.raspberrypi.org/raspbian/images/raspbian-2020-02-14/
	# the only reason we don't use lite image is that it doesn't have enough
	# space to install ROS dependencies, it is possible to resize it, but not
	# necessary for this demo
	${MAKE} download PROFILE=cross_raspberry_pi \
		FILES="https://github.com/Pro/raspi-toolchain/releases/download/v1.0.2/raspi-toolchain.tar.gz \
			   http://downloads.raspberrypi.org/raspbian/images/raspbian-2020-02-14/2021-05-07-raspios-buster-armhf.zip"
	bash -c "${SETUP_SCRIPT_cross_raspberry_pi}; \
		cd \"\$${CCW_PROFILE_BUILD_DIR}\"; \
		tar -xf raspi-toolchain.tar.gz; \
		unzip 2021-05-07-raspios-buster-armhf.zip; \
		mv cross-pi-gcc \"\$${CCW_PROFILE_DIR}\"; \
		mv 2021-05-07-raspios-buster-armhf.img \"\$${CCW_PROFILE_DIR}/system.img\""
	${MAKE} cross_raspberry_pi_fix_image

# TODO can we do something less hacky?
# we remove some heavy packages to get some free space for ROS dependencies
cross_raspberry_pi_fix_image:
	${MAKE} cross_raspberry_pi_init
	-bash -c "${SETUP_SCRIPT_cross_raspberry_pi}; \
		cd \"\$${CCW_SYSROOT}\"; \
		sudo cp /usr/bin/qemu-arm-static ./usr/bin/; \
		sudo chroot ./ /bin/sh -c \
			'apt purge --yes chromium-browser libgl1-mesa-dri git realvnc-vnc-server; \
			apt clean; \
			apt update; \
			apt --yes upgrade; \
			apt clean; \
			apt install --yes --no-install-recommends \
				librosconsole-bridge-dev libpoco-dev libpython3-dev \
				libboost-filesystem-dev libboost-program-options-dev \
				liblz4-dev libbz2-dev\
				libgpgme-dev \
				libgmock-dev libtinyxml2-dev; \
			apt clean'"
	#${MAKE} sysroot_fix_abs_symlinks PROFILE=cross_raspberry_pi
	${MAKE} cross_raspberry_pi_deinit


cross_raspberry_pi_clean:
	bash -c "${SETUP_SCRIPT_cross_raspberry_pi}; \
		cd \"\$${CCW_PROFILE_BUILD_DIR}\"; \
		rm -Rf *.gz* *.zip*; \
		rm -Rf cross-pi-gcc; \
		rm -Rf *.img"

cross_raspberry_pi_init: cross_raspberry_pi_deinit
	sudo bash -c "${SETUP_SCRIPT_cross_raspberry_pi}; \
		cd \"\$${CCW_PROFILE_DIR}\"; \
		CCW_SYSROOT_DEVICE=\$$(sudo losetup -PL --find --show ./system.img); \
		mount \"\$${CCW_SYSROOT_DEVICE}p2\" \"\$${CCW_SYSROOT}\" "
#		mkdir -p \"\$${CCW_SYSROOT}/\$${CCW_WORKSPACE_DIR}/\"; \
#		mkdir -p \"\$${CCW_SYSROOT}/\$${CCW_COMPILER_ROOT}/\"; \
#		mkdir -p \"\$${CCW_SYSROOT}/host-rootfs/\"; \
#		mount --bind \"\$${CCW_WORKSPACE_DIR}\" \"\$${CCW_SYSROOT}/\$${CCW_WORKSPACE_DIR}/\"; \
#		mount --bind \"\$${CCW_PROFILE_DIR}/cross-pi-gcc\" \"\$${CCW_SYSROOT}/\$${CCW_COMPILER_ROOT}/\"; \
#		mount --bind / \"\$${CCW_SYSROOT}/host-rootfs/\" "

cross_raspberry_pi_deinit:
	sudo bash -c "${SETUP_SCRIPT_cross_raspberry_pi}; \
		rm -Rf /opt/cross-pi-gcc || true; \
		umount --recursive \"\$${CCW_SYSROOT}\" || true"
