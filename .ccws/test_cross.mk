export BUILD_PROFILE?=cross_raspberry_pi

test:
	${MAKE} purge
	${MAKE} bprof_install_build
	${MAKE} wsinit REPOS="https://github.com/asherikov/staticoma.git"
	${MAKE} dep_to_repolist PKG=staticoma
	${MAKE} dep_to_repolist
	${MAKE} wsupdate
	${MAKE} bprof_install_host PKG=staticoma
	${MAKE} cross_mount
	${MAKE} staticoma
	${MAKE} wsclean
	${MAKE} staticoma BUILD_PROFILE=deb BASE_BUILD_PROFILE=${BUILD_PROFILE}
	${MAKE} cross_umount
