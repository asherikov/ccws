include make/config.mk

PROFILE?=reldebug
EMAIL?=XXX_email_unset_XXX
AUTHOR?=XXX_author_unset_XXX

WORKSPACE_DIR=$(shell pwd)

SETUP_SCRIPT=source ${WORKSPACE_DIR}/profiles/${PROFILE}/setup.bash
ARGS?=

MEMORY_PER_JOB_MB?=1024
export JOBS?=$(shell ${WORKSPACE_DIR}/scripts/guess_jobs.sh ${MEMORY_PER_JOB_MB})


##
## Default target (build)
##

default: build
.DEFAULT:
	bash -c "colcon list --names-only --base-paths src/ | grep $@ | paste -d ' ' -s | xargs -I {} ${MAKE} PKG=\"{}\""

# include after default targets to avoid shadowing them
-include make/*.mk



##
## Workspace targets
##

wsinstall_ubuntu18:
	apt install \
		python3-colcon-ros \
		python3-colcon-parallel-executor \
		python3-colcon-package-selection \
		python3-colcon-package-information
	apt install python3-wstool


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
	git pull
	${MAKE} wsupdate_pkgs

# Update workspace & all packages
wsupdate_pkgs:
	cd src; wstool update -j${JOBS} --continue-on-error


# Clean workspace
wsclean:
	find ./artifacts -maxdepth 1 -mindepth 1 -not -name "\.gitignore" | xargs rm -Rf
	rm -Rf build*
	rm -Rf devel*
	rm -Rf install*
	rm -Rf log*
	rm -Rf src/.rosinstall.bak


# Purge workspace
wspurge: wsclean
	rm -Rf src


##
## Package targets
##

assert_PKG_arg_must_be_specified:
	test "${PKG}" != ""

build: assert_PKG_arg_must_be_specified
	bash -c "${SETUP_SCRIPT}; \$${CCW_BUILD_WRAPPER} colcon \
		--log-base log/${PROFILE} \
		--log-level DEBUG \
		build \
		--build-base build/${PROFILE} \
		--install-base install/${PROFILE} \
		\$${COLCON_BUILD_ARGS} \
		--parallel-workers ${JOBS} \
		--packages-up-to ${PKG}"

# this target uses colcon and unlike `ctest` target does not respect `--output-on-failure`
test: assert_PKG_arg_must_be_specified
	bash -c "${SETUP_SCRIPT}; \
		colcon test \
		--build-base build/${PROFILE} \
		--install-base install/${PROFILE} \
		\$${COLCON_TEST_ARGS} \
		--parallel-workers ${JOBS} \
		--packages-select ${PKG}"
	${MAKE} showtestresults

ctest: assert_PKG_arg_must_be_specified
	bash -c "${SETUP_SCRIPT}; \
		cd build/${PROFILE}/${PKG}; \
		time ctest --output-on-failure --output-log \$${CCW_ARTIFACTS_DIR}/ctest_${PKG}.log -j ${JOBS}"
	${MAKE} showtestresults

showtestresults: assert_PKG_arg_must_be_specified
	# shows fewer tests
	colcon test-result --all --test-result-base ./build/${PROFILE}/${PKG}
	#bash -c "${SETUP_SCRIPT}; catkin_test_results ./build/${PROFILE}/${PKG}"


new: assert_PKG_arg_must_be_specified
	cp -R pkg_template src/${PKG}
	mkdir -p src/${PKG}/include/${PKG}
	cd src/${PKG}; git init
	find src/${PKG} -type f | xargs sed -i "s/@@PACKAGE@@/${PKG}/g"
	find src/${PKG} -type f | xargs sed -i "s/@@AUTHOR@@/${AUTHOR}/g"
	find src/${PKG} -type f | xargs sed -i "s/@@EMAIL@@/${EMAIL}/g"
	find src/${PKG} -type f | xargs sed -i "s/@@LICENSE@@/${LICENSE}/g"


##
## Other targets
##

help:
	@grep -v "^	" Makefile | grep -v "^ " | grep -v "^$$" | grep -v "^\."

.PHONY: build clean test rosdep install
