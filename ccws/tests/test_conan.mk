THIS_MAKEFILE=ccws/tests/test_conan.mk
WORKSPACE_SRC?=src

test:
	# conan
	${MAKE} wspurge
	${MAKE} bp_install_build
	${MAKE} install_conan
	cp -R ccws/tests/conan "${WORKSPACE_SRC}"
	${MAKE} conan_test

