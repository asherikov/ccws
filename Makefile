include make/config.mk

EMAIL?=$(shell git config --get user.email)
AUTHOR?=$(shell git config --get user.name)

WORKSPACE_DIR=$(shell pwd)

SETUP_SCRIPT=source ${WORKSPACE_DIR}/profiles/${PROFILE}/setup.bash
DEB_SETUP_SCRIPT=source ${WORKSPACE_DIR}/profiles/common/deb.bash
ARGS?=

MEMORY_PER_JOB_MB?=1024
export JOBS?=$(shell ${WORKSPACE_DIR}/scripts/guess_jobs.sh ${MEMORY_PER_JOB_MB})

export AUTHOR
export EMAIL

export AUTHOR
export EMAIL


##
## Default target (build)
##

default: build
.DEFAULT:
	bash -c "${MAKE} --quiet wslist | grep $@ | paste -d ' ' -s | xargs -I {} ${MAKE} PKG=\"{}\""

# include after default targets to avoid shadowing them
-include make/*.mk
-include profiles/*/*.mk



##
## Workspace targets
##

wslist:
	@colcon list --names-only --base-paths src/

# Reset & initialize workspace
wsinit: wspurge
	mkdir -p src
	cd src; wstool init

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


# Clean workspace
wsclean:
	find ${WORKSPACE_DIR}/artifacts -maxdepth 1 -mindepth 1 -not -name "\.gitignore" | xargs rm -Rf
	rm -Rf build*
	rm -Rf devel*
	rm -Rf install*
	rm -Rf log*
	rm -Rf src/.rosinstall.bak


# Purge workspace
wspurge: wsclean
	rm -Rf src


wsdep_to_rosinstall:
	rm -Rf ${WORKSPACE_DIR}/build/deplist
	bash -c "${MAKE} --quiet wslist | xargs -I {} ${MAKE} deplist PKG=\"{}\""
	rm -Rf ${WORKSPACE_DIR}/build/deplist/*.all	${WORKSPACE_DIR}/build/deplist/ccws.list
	cat ${WORKSPACE_DIR}/build/deplist/* | sort | uniq > ${WORKSPACE_DIR}/build/deplist/ccws.deps.all
	${MAKE} rosinstall_extend PKG_LIST="${WORKSPACE_DIR}/build/deplist/ccws.deps.all"


wsprepare_build:
	bash -c "${SETUP_SCRIPT}; \
		mkdir -p \"\$${CCWS_BUILD_DIR}\"; \
		mkdir -p \"\$${CCWS_INSTALL_DIR_HOST}/ccws/\"; "

wsclean_build:
	bash -c "${SETUP_SCRIPT}; rm -Rf \"\$${CCWS_BUILD_DIR}\""


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

deb_native:
	${MAKE} deb_mount
	${MAKE} deb
	${MAKE} deb_umount

deb_mount: assert_PKG_arg_must_be_specified
	bash -c "${DEB_SETUP_SCRIPT}; ${SETUP_SCRIPT}; \
		mkdir -p \"\$${CCWS_INSTALL_DIR_HOST}\"; \
		sudo mkdir -p \"\$${CCWS_INSTALL_DIR_TARGET}\"; \
		sudo mount --bind \"\$${CCWS_INSTALL_DIR_HOST}\" \"\$${CCWS_INSTALL_DIR_TARGET}\" "

deb_umount:
	bash -c "${DEB_SETUP_SCRIPT}; ${SETUP_SCRIPT}; \
		sudo umount --recursive \"\$${CCWS_INSTALL_DIR_TARGET}\" "

deb:
	bash -c "${DEB_SETUP_SCRIPT}; ${SETUP_SCRIPT};  \
		${MAKE} build; \
		mkdir -p \"\$${CCWS_INSTALL_DIR_HOST_ROOT}/DEBIAN\"; \
		echo \"\$${CCWS_DEB_CONTROL}\"  >  \"\$${CCWS_INSTALL_DIR_HOST_ROOT}/DEBIAN/control\"; \
		dpkg-deb --root-owner-group --build \"\$${CCWS_INSTALL_DIR_HOST_ROOT}\" \"install/\$${CCWS_PKG_FULL_NAME}.deb\" "

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
		cd build/${PROFILE}/${PKG}; \
		time ctest --output-on-failure --output-log \$${CCWS_ARTIFACTS_DIR}/ctest_${PKG}.log -j ${JOBS}"
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
	colcon list --names-only --base-paths src/ --packages-up-to ${PKG} | xargs colcon info --base-paths src/ --packages-select

# generate list of dependencies which are not present in the workspace
deplist: assert_PKG_arg_must_be_specified
	mkdir -p ${WORKSPACE_DIR}/build/deplist
	${MAKE} --quiet wslist | sort > ${WORKSPACE_DIR}/build/deplist/ccws.list
	${MAKE} info_with_deps \
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

.PHONY: build clean test rosdep install
