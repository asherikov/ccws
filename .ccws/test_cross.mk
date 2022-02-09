export BUILD_PROFILE?=cross_raspberry_pi

test:
	${MAKE} bp_purge
	${MAKE} wspurge
	${MAKE} bp_install_build
	${MAKE} wsinit REPOS="https://github.com/asherikov/staticoma.git"
	${MAKE} dep_to_repolist PKG=staticoma
	${MAKE} dep_to_repolist
	${MAKE} wsupdate
	${MAKE} cross_install PKG=staticoma
	${MAKE} cross_pack
	${MAKE} cross_purge
	${MAKE} cross_unpack
	${MAKE} cross_mount
	${MAKE} staticoma
	${MAKE} wsclean
	${MAKE} bp_install_build BUILD_PROFILE=deb
	${MAKE} staticoma BUILD_PROFILE=deb BASE_BUILD_PROFILE=${BUILD_PROFILE}
	${MAKE} deb_lint PKG=staticoma BUILD_PROFILE=deb BASE_BUILD_PROFILE=${BUILD_PROFILE}
	${MAKE} cross_umount

