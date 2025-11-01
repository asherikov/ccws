THIS_MAKEFILE=ccws/tests/test_conan.mk
TEST_SOURCE_DIR?=src

test:
	# conan
	${MAKE} wspurge
	${MAKE} bp_install_build
	${MAKE} install_conan
	cp -R ccws/tests/conan "${TEST_SOURCE_DIR}"
	${MAKE} conan_test

