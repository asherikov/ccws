THIS_MAKEFILE=ccws/tests/test_nix.mk
GIT_AUTHOR_NAME=nix_test
GIT_AUTHOR_EMAIL=nix_test
TEST_SOURCE_DIR?=src

test:
	# flakes use git
	git config --get user.email > /dev/null || git config --global user.email "you@example.com"
	shell git config --get user.name || git config --global user.name "Your Name"
	# nix
	${MAKE} wspurge
	${MAKE} bp_install_build
	${MAKE} install_nix
	cp -R ccws/tests/nix "${TEST_SOURCE_DIR}"
	${MAKE} nix_workspace_flake PKG=eigen
	rm .gitignore # src is ignored
	git add "${TEST_SOURCE_DIR}"/*.nix
	git commit -m "nix flake test"
	${MAKE} nix_test

