export PROFILE?=cross_raspberry_pi

test:
	${MAKE} purge
	${MAKE} install_build
	${MAKE} wsinit REPOS="https://github.com/asherikov/staticoma.git"
	${MAKE} dep_to_repolist PKG=staticoma
	${MAKE} dep_to_repolist
	${MAKE} wsupdate
	${MAKE} install_host PKG=staticoma
	${MAKE} cross_mount
	${MAKE} staticoma
	${MAKE} wsclean
	${MAKE} deb PKG=staticoma
	${MAKE} cross_umount
