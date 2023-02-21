-include make/config.mk

# obtain from gitconfig by default
export EMAIL?=$(shell git config --get user.email)
export AUTHOR?=$(shell git config --get user.name)
# no default, can be derived in many cases, in some must be set explicitly
export ROS_DISTRO

# default profile
export BUILD_PROFILE?=reldebug
# used in build profile mixins and profile creation targets
export BASE_BUILD_PROFILE?=reldebug
# default package type
export PKG_TYPE?=catkin
# global version, string, added to deb package names to enable multiple installations
export VERSION?=staging
# Used in binary package names
export VENDOR?=ccws
# default new package license
export LICENSE?=Apache 2.0


export WORKSPACE_DIR=$(shell pwd)
export ARTIFACTS_DIR=${WORKSPACE_DIR}/artifacts

# maximum amout of memory required for a single compilation job -- used to compute job limit
MEMORY_PER_JOB_MB?=2048
export JOBS?=$(shell ${WORKSPACE_DIR}/scripts/guess_jobs.sh ${MEMORY_PER_JOB_MB})
export CCWS_CACHE?=${WORKSPACE_DIR}/cache

export OS_DISTRO_BUILD?=$(shell lsb_release -cs)


# helpers
export BUILD_PROFILES_DIR=${WORKSPACE_DIR}/profiles/build/
export EXEC_PROFILES_DIR=${WORKSPACE_DIR}/profiles/exec/
SETUP_SCRIPT?=source ${BUILD_PROFILES_DIR}/${BUILD_PROFILE}/setup.bash
CMD_PKG_NAME_LIST=colcon --log-base /dev/null list --topological-order --names-only --base-paths ${WORKSPACE_DIR}/src/
CMD_PKG_LIST=colcon --log-base /dev/null list --topological-order --base-paths ${WORKSPACE_DIR}/src/
CMD_PKG_INFO=colcon --log-base /dev/null info --base-paths ${WORKSPACE_DIR}/src/
CMD_PKG_GRAPH=colcon graph --base-paths src/ --dot --dot-cluster


##
## Default target (build)
##

default: build
.DEFAULT:
	make build_glob PKG_NAME_PART=$@

# include after default targets to avoid shadowing them
-include profiles/*/*/*.mk
-include make/*.mk

# make tries to remake missing files, intercept these attempts
profiles/%/%.mk:
	@false
make/%.mk:
	@false


##
## Workspace targets
##

log_output:
	mkdir -p ${ARTIFACTS_DIR}/${MAKE}
	${MAKE} log_output_to_file OUTPUT_LOG_FILE=\"${ARTIFACTS_DIR}/${MAKE}/${TARGET}_${OUTPUT_LOG_ID}_`env | md5sum | cut -f 1 -d ' '`.log\"

log_output_to_file:
	${MAKE} ${TARGET} 2>&1 | ts "[%F %T %.s]" > ${OUTPUT_LOG_FILE}


# warning: MAKEFLAGS set in setup scripts is overriden by make
wswraptarget:
	bash -c "time (${SETUP_SCRIPT}; ${MAKE} ${TARGET})"

wslist:
	@${CMD_PKG_NAME_LIST}

# Reset & initialize workspace
wsinit:
	test ! -f src/.rosinstall
	mkdir -p src
	cd src; wstool init
	cd src; bash -c "echo '${REPOS}' | sed -e 's/ \+/ /g' -e 's/ /\n/g' | xargs -P ${JOBS} --no-run-if-empty -I {} git clone {}"
	-${MAKE} wsscrape_all
	${MAKE} wsupdate

# Status packages in the workspace
wsstatus:
	git status
	${MAKE} wsstatuspkg

wsstatuspkg:
	cd src; wstool info

# Add new packages to the workspace
wsscrape:
	cd src; wstool scrape

wsscrape_all:
	cd src; wstool scrape -y

# Update workspace & all packages
wsupdate:
	-git pull --rebase
	${MAKE} wsupdate_pkgs

wsupdate_shallow:
	-git pull
	mv src/.rosinstall src/.rosinstall.orig
	cd src; wstool init -j${JOBS} --shallow ./ .rosinstall.orig

# Update workspace & all packages
wsupdate_pkgs:
	cd src; wstool update -j${JOBS} --continue-on-error


show_vendor_files:
	@find ./profiles/*/vendor* ! -type d

ccache_stats:
	bash -c "${SETUP_SCRIPT}; ccache --show-stats"


##
## Package targets
##

assert_PKG_arg_must_be_specified:
	test "${PKG}" != ""

assert_AUTHOR_must_not_be_empty:
	test "${AUTHOR}" != ""

assert_EMAIL_must_not_be_empty:
	test "${EMAIL}" != ""


build_glob:
	bash -c "${MAKE} PKG=\"\$$(${CMD_PKG_NAME_LIST} | grep ${PKG_NAME_PART} | paste -d ' ' -s)\""

build: assert_BUILD_PROFILE_must_exist
	${MAKE} wswraptarget TARGET=bp_${BUILD_PROFILE}_build

bp_%_build: private_build
	# skip to default

# --log-level DEBUG
private_build: assert_PKG_arg_must_be_specified
	mkdir -p "${CCWS_BUILD_DIR}"
	# override make flags to enable multithreaded builds
	env MAKEFLAGS="-j${JOBS}" ${CCWS_BUILD_WRAPPER} colcon \
		--log-base ${CCWS_LOG_DIR} \
		build \
		--merge-install \
		--executor sequential \
		--base-paths ${WORKSPACE_DIR}/src/ \
		--build-base "${CCWS_BUILD_DIR}" \
		--install-base "${CCWS_INSTALL_DIR_BUILD}" \
		--cmake-args -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TOOLCHAIN_FILE}" \
		--packages-up-to ${PKG}


new: assert_PKG_arg_must_be_specified
	mkdir -p src/
	cp -R pkg_template/catkin src/${PKG}
	mkdir -p src/${PKG}/include/${PKG}
	cd src/${PKG}; git init
	find src/${PKG} -type f | xargs sed -i "s/@@PACKAGE@@/${PKG}/g"
	find src/${PKG} -type f | xargs sed -i "s/@@AUTHOR@@/${AUTHOR}/g"
	find src/${PKG} -type f | xargs sed -i "s/@@EMAIL@@/${EMAIL}/g"
	find src/${PKG} -type f | xargs sed -i "s/@@LICENSE@@/${LICENSE}/g"

add:
	test -f src/.rosinstall || ${MAKE} wsinit
	cd src; bash -c "\
		DIR=\$$(basename ${REPO} | sed -e 's/\.git$$//'); \
		wstool set \$${DIR} --git ${REPO} --version-new=${VERSION} --confirm --update"


##
## Other targets
##

help:
	@grep -v "^	" Makefile make/*.mk | grep -v "^ " | grep -v "^$$" | grep -v "^\." | grep -v ".mk:$$"

.PHONY: build clean test install
