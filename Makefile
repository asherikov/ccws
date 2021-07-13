include make/config.mk

PROFILE?=reldebug
EMAIL?=$(shell git config --get user.email)
AUTHOR?=$(shell git config --get user.name)

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
-include profiles/*/*.mk



##
## Workspace targets
##


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
	find ${WORKSPACE_DIR}/artifacts -maxdepth 1 -mindepth 1 -not -name "\.gitignore" | xargs rm -Rf
	rm -Rf build*
	rm -Rf devel*
	rm -Rf install*
	rm -Rf log*
	rm -Rf src/.rosinstall.bak


# Purge workspace
wspurge: wsclean
	rm -Rf src

wsdeprosinstall:
	bash -c "colcon list --names-only --base-paths src/ | paste -d ' ' -s | xargs -I {} ${MAKE} deprosinstall PKG=\"{}\""


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
		--merge-install \
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
	colcon test-result --all --test-result-base ${WORKSPACE_DIR}/build/${PROFILE}/${PKG}
	#bash -c "${SETUP_SCRIPT}; catkin_test_results ${WORKSPACE_DIR}/build/${PROFILE}/${PKG}"


new: assert_PKG_arg_must_be_specified
	mkdir -p src/
	cp -R pkg_template src/${PKG}
	mkdir -p src/${PKG}/include/${PKG}
	cd src/${PKG}; git init
	find src/${PKG} -type f | xargs sed -i "s/@@PACKAGE@@/${PKG}/g"
	find src/${PKG} -type f | xargs sed -i "s/@@AUTHOR@@/${AUTHOR}/g"
	find src/${PKG} -type f | xargs sed -i "s/@@EMAIL@@/${EMAIL}/g"
	find src/${PKG} -type f | xargs sed -i "s/@@LICENSE@@/${LICENSE}/g"


deprosinstall: assert_PKG_arg_must_be_specified
	mkdir -p ${WORKSPACE_DIR}/build
	bash -c "${SETUP_SCRIPT}; colcon \
		info --packages-up-to ${PKG} \
		| grep '\(build:\)\|\(run:\)' \
		| sed -e 's/build://' -e 's/run://' -e 's/ /\n/g' \
		| sort | uniq | paste -s -d ' ' \
		| xargs  rosinstall_generator --tar --deps --rosdistro \$${CCW_ROS_DISTRO} > ${WORKSPACE_DIR}/build/deprosinstall"
	cd src; wstool merge -y ${WORKSPACE_DIR}/build/deprosinstall



##
## Other targets
##

help:
	@grep -v "^	" Makefile | grep -v "^ " | grep -v "^$$" | grep -v "^\."

.PHONY: build clean test rosdep install
