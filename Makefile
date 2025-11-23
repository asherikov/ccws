GNUMAKEFLAGS+= --no-print-directory
export GNUMAKEFLAGS

export CCWS_ROOT::=$(shell pwd)
export CCWS_DIR=${CCWS_ROOT}/ccws

-include ${CCWS_DIR}/make/config.mk

export WORKSPACE_DIR?=${CCWS_ROOT}
WORKSPACE_SRC?=${WORKSPACE_DIR}/src
override export WORKSPACE_SRC::=$(shell realpath "${WORKSPACE_SRC}")

-include ${WORKSPACE_SRC}/.ccws/config.mk


# obtain from gitconfig by default
export EMAIL?=$(shell git config --get user.email 2> /dev/null || echo "ccws@ccws.net")
export AUTHOR?=$(shell git config --get user.name 2> /dev/null || echo "ccws")
# no default, can be derived in many cases, in some must be set explicitly
export ROS_DISTRO

# build profiles (comma separated)
BUILD_PROFILE?=reldebug
# TODO DEPRECATED[use BUILD_PROFILE] used in build profile mixins and profile creation targets
BASE_BUILD_PROFILE?=

export CCWS_BUILD_PROFILES::=$(shell echo "${BUILD_PROFILE},${BASE_BUILD_PROFILE}" | sed -e 's/,,//g' -e 's/,$$//g')
export CCWS_BUILD_PROFILES_ID::=$(shell echo "${CCWS_BUILD_PROFILES}" | sed -e 's/,/_/g')
export CCWS_PRIMARY_BUILD_PROFILE::=$(shell echo ${CCWS_BUILD_PROFILES} | cut -f 1 -d ',')
export CCWS_SECONDARY_BUILD_PROFILE::=$(shell echo ${CCWS_BUILD_PROFILES} | cut -s -f 2 -d ',')
export CCWS_BUILD_PROFILES_TAIL::=$(shell echo ${CCWS_BUILD_PROFILES} | cut -s -f 2- -d ',')


# default package type
export PKG_TYPE?=catkin
# global version, string, added to deb package names to enable multiple installations
export VERSION?=staging
# Used in binary package names
export VENDOR?=ccws
# default new package license
export LICENSE?=Apache 2.0
export REPO_LIST_FORMAT?=repos

# Cache directory
# 1. keep cache in ccws root directory, old behavior, restore using config.mk if necessary
#export CCWS_CACHE?=${WORKSPACE_DIR}/cache
# 2. follow XDG specification
XDG_CACHE_HOME?=${HOME}/.cache
export CCWS_CACHE?=${XDG_CACHE_HOME}/ccws
export CCWS_SOURCE_DIR?=${WORKSPACE_SRC}

export CCWS_BUILD_DIR_BASE=${WORKSPACE_DIR}/build/
export CCWS_INSTALL_DIR_BASE=${WORKSPACE_DIR}/install/
export CCWS_ARTIFACTS_DIR_BASE=${WORKSPACE_DIR}/artifacts/
export CCWS_SYSROOT_DIR_BASE=${WORKSPACE_DIR}/sysroot/

export CCWS_BUILD_DIR=${CCWS_BUILD_DIR_BASE}/${CCWS_BUILD_PROFILES_ID}
export CCWS_INSTALL_DIR=${CCWS_INSTALL_DIR_BASE}/${CCWS_BUILD_PROFILES_ID}
export CCWS_ARTIFACTS_DIR?=${CCWS_ARTIFACTS_DIR_BASE}/${CCWS_BUILD_PROFILES_ID}
#export CCWS_SYSROOT_DIR=${CCWS_SYSROOT_DIR_BASE}/${CCWS_BUILD_PROFILES_ID}

export CCWS_TOOLS_DIR?=${CCWS_DIR}/tools
export PATH::=${CCWS_TOOLS_DIR}/bin:${PATH}

# maximum amout of memory required for a single compilation job -- used to compute job limit
MEMORY_PER_JOB_MB?=2048
export JOBS?=$(shell "${CCWS_TOOLS_DIR}/bin/guess_jobs.sh" ${MEMORY_PER_JOB_MB})


export OS_DISTRO_BUILD?=$(shell lsb_release -cs 2> /dev/null || echo "UKNOWN")

# default package to build can be specified in source directory or via command line,
# when not provided usually all packages in the workspace are processed
export PKG?=$(shell (cat "${CCWS_SOURCE_DIR}/.ccws/package" 2> /dev/null | sed -e 's/[[:space:]]*\#.*//' -e '/^[[:space:]]*$$/d' | paste -d ' ' -s) || echo "")
export PKG_ID::=$(shell echo "${PKG}" | md5sum | cut -f 1 -d ' ')


# helpers
export BUILD_PROFILES_DIR=${CCWS_DIR}/profiles/build/
export EXEC_PROFILES_DIR=${CCWS_DIR}/profiles/exec/
MAKE_QUIET=${MAKE} --quiet --no-print-directory
SETUP_SCRIPT?=source ${BUILD_PROFILES_DIR}/${CCWS_PRIMARY_BUILD_PROFILE}/setup.bash ${CCWS_BUILD_PROFILES_TAIL}
CMD_PKG_NAME_LIST=colcon --log-base /dev/null list --topological-order --names-only --base-paths ${CCWS_SOURCE_DIR}
CMD_PKG_LIST=colcon --log-base /dev/null list --topological-order --base-paths ${CCWS_SOURCE_DIR}
CMD_PKG_GRAPH=colcon graph --base-paths ${CCWS_SOURCE_DIR} --dot --dot-cluster
CMD_WSHANDLER=wshandler -r ${CCWS_SOURCE_DIR} -t ${REPO_LIST_FORMAT} -c ${CCWS_CACHE}/wshandler
CCWS_XARGS=xargs --no-run-if-empty -I {}


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
${CCWS_SOURCE_DIR}/.ccws/config.mk:
	@false


##
## Workspace targets
##

log_output:
	mkdir -p ${CCWS_ARTIFACTS_DIR}/${MAKE}
	${MAKE} log_output_to_file OUTPUT_LOG_FILE=\"${CCWS_ARTIFACTS_DIR}/${MAKE}/${TARGET}_${OUTPUT_LOG_ID}_`env | md5sum | cut -f 1 -d ' '`.log\"

log_output_to_file:
	${MAKE} ${TARGET} 2>&1 | ts "[%F %T %.s]" > ${OUTPUT_LOG_FILE}


# warning: MAKEFLAGS set in setup scripts is overriden by make
wswraptarget:
	bash -c "time (${SETUP_SCRIPT}; ${MAKE} --no-print-directory ${TARGET})"


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

assert_JOBS_arg_must_be_positive_integer:
	test "${JOBS}" -gt 0


build_glob:
	bash -c "${MAKE} PKG=\"\$$(${CMD_PKG_NAME_LIST} | grep '${PKG_NAME_PART}' | paste -d ' ' -s)\""

build_all:
	bash -c "${MAKE} PKG=\"\$$(${CMD_PKG_NAME_LIST} | paste -d ' ' -s)\""

build: assert_BUILD_PROFILES_must_exist
	${MAKE} wswraptarget TARGET=bp_${CCWS_PRIMARY_BUILD_PROFILE}_build

bp_%_build: private_build
	# skip to default

# --log-level DEBUG
private_build: assert_PKG_arg_must_be_specified assert_JOBS_arg_must_be_positive_integer
	mkdir -p "${CCWS_BUILD_DIR}"
	mkdir -p "${CCWS_ARTIFACTS_DIR}"
	# override make flags to enable multithreaded builds
	# CMAKE_INSTALL_PREFIX does not have effect if set only in toolchain when rebuilding
	env MAKEFLAGS="-j${JOBS}" ${CCWS_BUILD_WRAPPER} colcon \
		--log-base ${CCWS_LOG_DIR} \
		build \
		--event-handlers console_direct+ \
		--merge-install \
		--executor sequential \
		--base-paths "${CCWS_SOURCE_DIR}" \
		--build-base "${CCWS_BUILD_DIR}" \
		--install-base "${CCWS_INSTALL_DIR_BUILD}" \
		--cmake-args -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TOOLCHAIN_FILE}" -DCMAKE_INSTALL_PREFIX="${CCWS_INSTALL_DIR_HOST}" \
		--packages-up-to ${PKG}

##
## Other targets
##

help:
	@grep -v "^	" Makefile ${CCWS_DIR}/make/*.mk | grep -v "^ " | grep -v "^$$" | grep -v "^\." | grep -v ".mk:$$"

readme:
	cp README.md README.md.back
	# crop old toc
	sed '/^Introduction$$/,$$!d' README.md.back > README.md
	pandoc --standalone --columns=80 --markdown-headings=setext --tab-stop=4 --from=gfm --to=gfm --toc --toc-depth=2 README.md -o README.fmt.md
	mv README.fmt.md README.md

.PHONY: build clean test install default all
