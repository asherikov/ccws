THIS_MAKEFILE=.ccws/test_vcpkg.mk

test:
	# vcpkg
	${MAKE} wspurge
	${MAKE} bp_install_build
	${MAKE} install_vcpkg
	cp -R .ccws/vcpkg src
	${MAKE} vcpkg_test

