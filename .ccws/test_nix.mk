THIS_MAKEFILE=.ccws/test_nix.mk
GIT_AUTHOR_NAME=nix_test
GIT_AUTHOR_EMAIL=nix_test

test:
	# flakes use git
	git config --get user.email > /dev/null || git config --global user.email "you@example.com"
	shell git config --get user.name || git config --global user.name "Your Name"
	# nix
	${MAKE} wspurge
	${MAKE} bp_install_build
	${MAKE} install_nix
	cp -R .ccws/nix src
	${MAKE} nix_workspace_flake PKG=eigen
	git add src/*.nix
	git commit -m "nix flake test"
	${MAKE} nix_test

