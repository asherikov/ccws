THIS_MAKEFILE=.ccws/test_main.mk

test:
	# package & profile creation
	${MAKE} wspurge
	rm -Rf profiles/build/test_profile/
	${MAKE} bp_new BUILD_PROFILE=test_profile BASE_BUILD_PROFILE=reldebug
	${MAKE} bp_install_build BUILD_PROFILE=test_profile
	${MAKE} wsinit
	${MAKE} new PKG=test_pkg EMAIL=example@example.org AUTHOR=example
	${MAKE} wsscrape_all
	${MAKE} dep_to_repolist PKG=test_pkg
	${MAKE} wsupdate
	${MAKE} log_output TARGET=wsstatus
	${MAKE} dep_install PKG=test_pkg
	${MAKE} test_pkg BUILD_PROFILE=test_profile
	# reset
	${MAKE} bp_purge
	${MAKE} wspurge
	${MAKE} wsinit REPOS="https://github.com/asherikov/staticoma.git"
	# add dependencies to the workspace and build deb package
	${MAKE} dep_to_repolist PKG=staticoma
	${MAKE} dep_to_repolist
	${MAKE} wsupdate
	${MAKE} dep_install PKG=staticoma
	${MAKE} dep_install
	${MAKE} bp_install_build BUILD_PROFILE=deb
	${MAKE} staticoma BUILD_PROFILE=deb BASE_BUILD_PROFILE=reldebug
	${MAKE} deb_lint PKG=staticoma BUILD_PROFILE=deb BASE_BUILD_PROFILE=reldebug
	sudo dpkg -i artifacts/*/*.deb
	dpkg --get-selections | grep staticoma | cut -f 1 |  xargs sudo apt purge --yes
	# clangd
	${MAKE} bp_install_build BUILD_PROFILE=clangd
	${MAKE} BUILD_PROFILE=clangd BASE_BUILD_PROFILE=reldebug
	wc -l cache/clangd/reldebug/compile_commands.json
	# drop downloaded ROS packages, we are going to install binaries
	${MAKE} wsclean
	mv src/staticoma ./
	rm -Rf ./src/*
	mv staticoma ./src/
	${MAKE} dep_install PKG=staticoma
	# test various build profiles
	${MAKE} -f ${THIS_MAKEFILE} build_with_profile BUILD_PROFILE=addr_undef_sanitizers
	${MAKE} -f ${THIS_MAKEFILE} build_with_profile BUILD_PROFILE=thread_sanitizer
	${MAKE} -f ${THIS_MAKEFILE} build_with_profile BUILD_PROFILE=scan_build
	${MAKE} -f ${THIS_MAKEFILE} build_with_profile BUILD_PROFILE=reldebug
	# check valgrind exec profile
	${MAKE} ep_install EXEC_PROFILE=valgrind
	${MAKE} wstest PKG=staticoma EXEC_PROFILE=valgrind
	# check core_pattern exec profile
	${MAKE} ep_install EXEC_PROFILE=core_pattern
	${MAKE} wstest PKG=staticoma EXEC_PROFILE="core_pattern valgrind"
	# static checks & documentation
	${MAKE} bp_install_build BUILD_PROFILE=static_checks
	${MAKE} BUILD_PROFILE=static_checks
	${MAKE} bp_install_build BUILD_PROFILE=doxygen
	${MAKE} PKG=staticoma BUILD_PROFILE=doxygen
	${MAKE} BUILD_PROFILE=doxygen

build_with_profile:
	${MAKE} wsclean
	${MAKE} bp_install_build
	${MAKE} staticoma
	${MAKE} wstest
	${MAKE} wsctest
