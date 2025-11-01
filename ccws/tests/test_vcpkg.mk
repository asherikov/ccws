THIS_MAKEFILE=ccws/tests/test_vcpkg.mk
TEST_SOURCE_DIR?=src

test:
	# vcpkg
	${MAKE} wspurge
	${MAKE} bp_install_build
	${MAKE} install_vcpkg
	cp -R ccws/tests/vcpkg "${TEST_SOURCE_DIR}"
	${MAKE} vcpkg_test

