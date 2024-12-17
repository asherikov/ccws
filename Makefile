GNUMAKEFLAGS+= --no-print-directory
export GNUMAKEFLAGS

export CCWS_ROOT=$(shell pwd)
export CCWS_DIR=${CCWS_ROOT}/ccws

-include ${CCWS_DIR}/make/config.mk

export WORKSPACE_DIR?=${CCWS_ROOT}
WORKSPACE_SRC?=${WORKSPACE_DIR}/src
override export WORKSPACE_SRC::=$(shell realpath "${WORKSPACE_SRC}")

-include ${WORKSPACE_SRC}/.ccws/config.mk


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
export REPO_LIST_FORMAT?=repos

export WORKSPACE_INSTALL?=${WORKSPACE_DIR}/install/${BUILD_PROFILE}
export ARTIFACTS_DIR=${WORKSPACE_DIR}/artifacts

# maximum amout of memory required for a single compilation job -- used to compute job limit
MEMORY_PER_JOB_MB?=2048
export JOBS?=$(shell ${CCWS_DIR}/scripts/guess_jobs.sh ${MEMORY_PER_JOB_MB})

# Cache directory
# 1. keep cache in ccws root directory, old behavior, restore using config.mk if necessary
#export CCWS_CACHE?=${WORKSPACE_DIR}/cache
# 2. follow XDG specification
XDG_CACHE_HOME?=${HOME}/.cache
export CCWS_CACHE?=${XDG_CACHE_HOME}/ccws

export OS_DISTRO_BUILD?=$(shell lsb_release -cs)

# default package to build can be specified in source directory or via command line,
# when not provided usually all packages in the workspace are processed
export PKG?=$(shell (cat "${WORKSPACE_SRC}/.ccws/package" 2> /dev/null | sed -e 's/[[:space:]]*\#.*//' -e '/^[[:space:]]*$/d' | paste -d ' ' -s) || echo "")
export PKG_ID=$(shell echo "${PKG}" | md5sum | cut -f 1 -d ' ')


# helpers
export BUILD_PROFILES_DIR=${CCWS_DIR}/profiles/build/
export EXEC_PROFILES_DIR=${CCWS_DIR}/profiles/exec/
MAKE_QUIET=${MAKE} --quiet --no-print-directory
SETUP_SCRIPT?=source ${BUILD_PROFILES_DIR}/${BUILD_PROFILE}/setup.bash
CMD_PKG_NAME_LIST=colcon --log-base /dev/null list --topological-order --names-only --base-paths ${WORKSPACE_SRC}
CMD_PKG_LIST=colcon --log-base /dev/null list --topological-order --base-paths ${WORKSPACE_SRC}
CMD_PKG_INFO=colcon --log-base /dev/null info --base-paths ${WORKSPACE_SRC}
CMD_PKG_GRAPH=colcon graph --base-paths ${WORKSPACE_SRC} --dot --dot-cluster
CMD_WSHANDLER=${CCWS_DIR}/scripts/wshandler -r ${WORKSPACE_SRC} -t ${REPO_LIST_FORMAT} -c ${CCWS_CACHE}/wshandler


##
## Default target (build)
##

default: build
.DEFAULT:
	make build_glob PKG_NAME_PART=$@

# include after default targets to avoid shadowing them
-include ${CCWS_DIR}/profiles/*/*/*.mk
-include ${CCWS_DIR}/make/*.mk

# make tries to remake missing files, intercept these attempts
%.mk:
	@false
${WORKSPACE_SRC}/.ccws/config.mk:
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
	bash -c "time (${SETUP_SCRIPT}; ${MAKE} --no-print-directory ${TARGET})"

wslist:
	@test -z "${PKG}" || ${CMD_PKG_NAME_LIST} --packages-up-to ${PKG}
	@test -n "${PKG}" || ${CMD_PKG_NAME_LIST}


# Reset & initialize workspace
wsinit:
	! ${CMD_WSHANDLER} is_source_space
	mkdir -p "${WORKSPACE_SRC}"
	touch "${WORKSPACE_SRC}/.${REPO_LIST_FORMAT}"
	cd ${WORKSPACE_SRC}; bash -c "echo '${REPOS}' | sed -e 's/ \+/ /g' -e 's/ /\n/g' | xargs -P ${JOBS} --no-run-if-empty -I {} git clone {}"
	-${MAKE} wsscrape_all
	${MAKE} wsupdate

# Status packages in the workspace
wsstatus:
	git status
	${MAKE} wsstatuspkg

wsstatuspkg:
	${CMD_WSHANDLER} status

# Add new packages to the workspace
wsscrape:
	${CMD_WSHANDLER} scrape

wsscrape_all:
	${CMD_WSHANDLER} -p add scrape

# Update workspace & all packages
wsupdate:
	-git pull --rebase
	${MAKE} wsupdate_pkgs

wsupdate_shallow:
	-git pull --rebase
	${MAKE} wsupdate_pkgs_shallow

# Update workspace & all packages
wsupdate_pkgs:
	${CMD_WSHANDLER} -j ${JOBS} -k update

wsupdate_pkgs_shallow:
	${CMD_WSHANDLER} -j ${JOBS} -p shallow update

wsupdate_pkgs_shallow_rebase:
	${CMD_WSHANDLER} -j ${JOBS} -p shallow,rebase update


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
	bash -c "${MAKE} PKG=\"\$$(${CMD_PKG_NAME_LIST} | grep '${PKG_NAME_PART}' | paste -d ' ' -s)\""

build_all:
	bash -c "${MAKE} PKG=\"\$$(${CMD_PKG_NAME_LIST} | paste -d ' ' -s)\""

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
		--event-handlers console_direct+ \
		--merge-install \
		--executor sequential \
		--base-paths ${WORKSPACE_SRC} \
		--build-base "${CCWS_BUILD_DIR}" \
		--install-base "${CCWS_INSTALL_DIR_BUILD}" \
		--cmake-args -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TOOLCHAIN_FILE}" \
		--packages-up-to ${PKG}


add:
	${CMD_WSHANDLER} is_source_space || ${MAKE} wsinit
	bash -c "\
		DIR=\$$(basename ${REPO} | sed -e 's/\.git$$//'); \
		${CMD_WSHANDLER} add git \$${DIR} ${REPO} ${VERSION}"

graph:
	@test -z "${PKG}" || ${CMD_PKG_GRAPH} --packages-up-to ${PKG}
	@test -n "${PKG}" || ${CMD_PKG_GRAPH}


##
## Other targets
##

help:
	@grep -v "^	" Makefile ${CCWS_DIR}/make/*.mk | grep -v "^ " | grep -v "^$$" | grep -v "^\." | grep -v ".mk:$$"

.PHONY: build clean test install
