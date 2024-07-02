THIS_MAKEFILE=.ccws/test_vcpkg.mk
WORKSPACE_SRC?=src

test:
	# vcpkg
	${MAKE} wspurge
	${MAKE} bp_install_build
	${MAKE} install_vcpkg
	cp -R .ccws/vcpkg "${WORKSPACE_SRC}"
	${MAKE} vcpkg_test

