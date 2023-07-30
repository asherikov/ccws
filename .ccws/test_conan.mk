THIS_MAKEFILE=.ccws/test_conan.mk

test:
	# conan
	${MAKE} wspurge
	${MAKE} bp_install_build
	${MAKE} install_conan
	cp -R .ccws/conan src
	${MAKE} conan_test

