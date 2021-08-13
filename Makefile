include make/config.mk

EMAIL?=$(shell git config --get user.email)
AUTHOR?=$(shell git config --get user.name)

WORKSPACE_DIR=$(shell pwd)
OS_DISTRO=$(shell lsb_release -cs)

COLCON_LOGLESS=colcon --log-base /dev/null

SETUP_SCRIPT=source ${WORKSPACE_DIR}/profiles/${PROFILE}/setup.bash
DEB_SETUP_SCRIPT=source ${WORKSPACE_DIR}/profiles/common/deb.bash
ARGS?=

MEMORY_PER_JOB_MB?=1024
export JOBS?=$(shell ${WORKSPACE_DIR}/scripts/guess_jobs.sh ${MEMORY_PER_JOB_MB})

export AUTHOR
export EMAIL
export PROFILE
export WORKSPACE_DIR
export VERSION


##
## Default target (build)
##

default: build
.DEFAULT:
	bash -c "${MAKE} --quiet wslist | grep $@ | paste -d ' ' -s | xargs --no-run-if-empty -I {} ${MAKE} PKG=\"{}\""

# include after default targets to avoid shadowing them
-include profiles/*/*.mk
-include make/*.mk



##
## Workspace targets
##

wslist:
	@${COLCON_LOGLESS} list --names-only --base-paths src/

# Reset & initialize workspace
wsinit: wspurge
	mkdir -p src
	cd src; wstool init
	cd src; bash -c "echo '${REPOS}' | sed -e 's/ \+/ /g' -e 's/ /\n/g' | xargs -P ${JOBS} --no-run-if-empty -I {} git clone {}"
	-cd src; wstool scrape -y
	${MAKE} wsupdate

# Status packages in the workspace
wsstatus:
	git status
	cd src; wstool info


# Add new packages to the workspace
wsscrape:
	cd src; wstool scrape

# Update workspace & all packages
wsupdate:
	-git pull
	${MAKE} wsupdate_pkgs

# Update workspace & all packages
wsupdate_pkgs:
	cd src; wstool update -j${JOBS} --continue-on-error


wsdep_to_rosinstall:
	rm -Rf ${WORKSPACE_DIR}/build/deplist
	bash -c "${MAKE} --no-print-directory --quiet wslist | xargs -I {} ${MAKE} deplist PKG=\"{}\""
	rm -Rf ${WORKSPACE_DIR}/build/deplist/*.all	${WORKSPACE_DIR}/build/deplist/ccws.list
	cat ${WORKSPACE_DIR}/build/deplist/* | sort | uniq > ${WORKSPACE_DIR}/build/deplist/ccws.deps.all
	${MAKE} rosinstall_extend PKG_LIST="${WORKSPACE_DIR}/build/deplist/ccws.deps.all"


wsprepare_build:
	bash -c "${SETUP_SCRIPT}; \
		mkdir -p \"\$${CCWS_BUILD_DIR}\"; \
		mkdir -p \"\$${CCWS_INSTALL_DIR_HOST}/ccws/\"; "


##
## Package targets
##

assert_PKG_arg_must_be_specified:
	test "${PKG}" != ""

build: assert_PKG_arg_must_be_specified wsprepare_build
	bash -c "${SETUP_SCRIPT}  \
		&& \$${CCWS_BUILD_WRAPPER} colcon \
		--log-base log/${PROFILE} \
		build \
		--merge-install \
		--build-base build/${PROFILE} \
		\$${COLCON_BUILD_ARGS} \
		--parallel-workers ${JOBS} \
		--packages-up-to ${PKG} \
		&& cp ${WORKSPACE_DIR}/scripts/colcon_setup.bash \"\$${CCWS_INSTALL_DIR_HOST}/setup.bash\" \
		&& ${MAKE} wsstatus > \"\$${CCWS_INSTALL_DIR_HOST}/ccws/workspace_status.txt\" \
		&& echo \"${PKG}\" > \"\$${CCWS_INSTALL_DIR_HOST}/ccws/pkg.txt\" \
		&& echo \$${CCWS_BUILD_USER} \$${CCWS_BUILD_TIME} > \"\$${CCWS_INSTALL_DIR_HOST}/ccws/build_info.txt\" "


version_hash: assert_PKG_arg_must_be_specified
	mkdir -p ${WORKSPACE_DIR}/build/version_hash
	${MAKE} --quiet info_with_deps \
		| grep path | sed 's/path: //' | sort \
		| xargs -I {} /bin/sh -c 'cd {}; echo {}; git show -s --format=%h; git diff' > ${WORKSPACE_DIR}/build/version_hash/${PKG}.all
	git show -s --format=%h >> ${WORKSPACE_DIR}/build/version_hash/${PKG}.all
	cat "${WORKSPACE_DIR}/build/version_hash/${PKG}.all" | md5sum | grep -o "^......" > ${WORKSPACE_DIR}/build/version_hash/${PKG}

rosdep_init:
	bash -c "${SETUP_SCRIPT}; \
		mkdir -p \"\$${CCWS_PROFILE_DIR}/rosdep\"; \
		mkdir -p \"\$${ROS_HOME}\"; \
		ln --symbolic --force --no-target-directory \"\$${CCWS_PROFILE_DIR}/rosdep\" \"\$${ROS_HOME}/rosdep\" "

rosdep_resolve: rosdep_init deplist
	bash -c "${SETUP_SCRIPT}; \
		test -d \"\$${ROS_HOME}/rosdep/sources.cache/\" || rosdep update; \
		rosdep resolve $$(cat ${WORKSPACE_DIR}/build/deplist/${PKG} | paste -s -d ' ') \
		| grep -v '^#' | sed 's/ /\n/g' | grep -v '^$$' | sort | uniq > \"${WORKSPACE_DIR}/build/deplist/${PKG}.deb\" "

deb_build: rosdep_resolve version_hash
	bash -c "${DEB_SETUP_SCRIPT}; ${MAKE} build"

deb_pack: assert_PKG_arg_must_be_specified
	bash -c "${DEB_SETUP_SCRIPT}; \
		mkdir -p \"\$${CCWS_INSTALL_DIR_HOST_ROOT}/DEBIAN\"; \
		chmod -R g-w \"\$${CCWS_INSTALL_DIR_HOST_ROOT}/\" ; \
		find \"\$${CCWS_INSTALL_DIR_HOST_ROOT}/\" -iname '*.pyc' | xargs --no-run-if-empty rm; \
		echo \"\$${CCWS_DEB_CONTROL}\"                                    >  \"\$${CCWS_INSTALL_DIR_HOST_ROOT}/DEBIAN/control\"; \
		echo -n 'Depends: '                                               >> \"\$${CCWS_INSTALL_DIR_HOST_ROOT}/DEBIAN/control\"; \
		cat '${WORKSPACE_DIR}/build/deplist/${PKG}.deb' | paste -s -d ',' >> \"\$${CCWS_INSTALL_DIR_HOST_ROOT}/DEBIAN/control\"; \
		dpkg-deb --root-owner-group --build \"\$${CCWS_INSTALL_DIR_HOST_ROOT}\" \"install/\$${CCWS_PKG_FULL_NAME}.deb\" "

# see https://lintian.debian.org/tags/
deb_lint: assert_PKG_arg_must_be_specified
	bash -c "${DEB_SETUP_SCRIPT}; \
	lintian \"install/\$${CCWS_PKG_FULL_NAME}.deb\" "

deb:
	${MAKE} deb_build
	${MAKE} deb_pack


# this target uses colcon and unlike `ctest` target does not respect `--output-on-failure`
test: assert_PKG_arg_must_be_specified
	bash -c "${SETUP_SCRIPT}; \
		colcon test \
		--build-base build/${PROFILE} \
		\$${COLCON_TEST_ARGS} \
		--parallel-workers ${JOBS} \
		--packages-select ${PKG}"
	${MAKE} showtestresults

ctest: assert_PKG_arg_must_be_specified
	bash -c "${SETUP_SCRIPT}; \
		mkdir -p \"\$${CCWS_ARTIFACTS_DIR}/\$${PROFILE}\"; \
		cd build/${PROFILE}/${PKG}; \
		time ctest --output-on-failure --output-log \"\$${CCWS_ARTIFACTS_DIR}/\$${PROFILE}/ctest_${PKG}.log\" -j ${JOBS}"
	${MAKE} showtestresults

showtestresults: assert_PKG_arg_must_be_specified
	# shows fewer tests
	colcon test-result --all --test-result-base ${WORKSPACE_DIR}/build/${PROFILE}/${PKG}
	#bash -c "${SETUP_SCRIPT}; catkin_test_results ${WORKSPACE_DIR}/build/${PROFILE}/${PKG}"


new: assert_PKG_arg_must_be_specified
	mkdir -p src/
	cp -R pkg_template/catkin src/${PKG}
	mkdir -p src/${PKG}/include/${PKG}
	cd src/${PKG}; git init
	find src/${PKG} -type f | xargs sed -i "s/@@PACKAGE@@/${PKG}/g"
	find src/${PKG} -type f | xargs sed -i "s/@@AUTHOR@@/${AUTHOR}/g"
	find src/${PKG} -type f | xargs sed -i "s/@@EMAIL@@/${EMAIL}/g"
	find src/${PKG} -type f | xargs sed -i "s/@@LICENSE@@/${LICENSE}/g"

# `colcon info --packages-up-to <pkg>` is buggy -> https://github.com/colcon/colcon-core/issues/443
info_with_deps: assert_PKG_arg_must_be_specified
	@${COLCON_LOGLESS} list --names-only --base-paths src/ --packages-up-to ${PKG} | xargs ${COLCON_LOGLESS} info --base-paths src/ --packages-select

# generate list of dependencies which are not present in the workspace
deplist: assert_PKG_arg_must_be_specified
	mkdir -p ${WORKSPACE_DIR}/build/deplist
	${MAKE} --quiet wslist | sort > ${WORKSPACE_DIR}/build/deplist/ccws.list
	${MAKE} --quiet info_with_deps \
		| grep '\(build:\)\|\(run:\)' \
		| sed -e 's/build://' -e 's/run://' -e 's/ /\n/g' \
		| sort | uniq | grep -v '^$$' > ${WORKSPACE_DIR}/build/deplist/${PKG}.all
	# remove packages that are already in the workspace
	comm -13 ${WORKSPACE_DIR}/build/deplist/ccws.list ${WORKSPACE_DIR}/build/deplist/${PKG}.all > ${WORKSPACE_DIR}/build/deplist/${PKG}

dep_to_rosinstall: deplist
	${MAKE} rosinstall_extend PKG_LIST="${WORKSPACE_DIR}/build/deplist/${PKG}"

rosinstall_extend:
	bash -c "${SETUP_SCRIPT}; cat ${PKG_LIST} | paste -s -d ' ' \
		| xargs rosinstall_generator --deps --rosdistro \$${CCWS_ROS_DISTRO} > ${WORKSPACE_DIR}/build/deplist/${PKG}.rosinstall"
	cd src; wstool merge -y ${WORKSPACE_DIR}/build/deplist/${PKG}.rosinstall


##
## Other targets
##

help:
	@grep -v "^	" Makefile | grep -v "^ " | grep -v "^$$" | grep -v "^\."

.PHONY: build clean test install
