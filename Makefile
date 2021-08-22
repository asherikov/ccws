include make/config.mk

export EMAIL?=$(shell git config --get user.email)
export AUTHOR?=$(shell git config --get user.name)
export PROFILE
export VERSION
export ROS_DISTRO

export WORKSPACE_DIR=$(shell pwd)
export OS_DISTRO_BUILD=$(shell lsb_release -cs)

CMD_PKG_NAME_LIST=colcon --log-base /dev/null list --topological-order --names-only --base-paths ${WORKSPACE_DIR}/src/
CMD_PKG_LIST=colcon --log-base /dev/null list --topological-order --base-paths ${WORKSPACE_DIR}/src/
CMD_PKG_INFO=colcon --log-base /dev/null info --base-paths ${WORKSPACE_DIR}/src/
CMD_PKG_GRAPH=colcon graph --base-paths src/ --dot


SETUP_SCRIPT=source ${WORKSPACE_DIR}/profiles/${PROFILE}/setup.bash
ARGS?=

MEMORY_PER_JOB_MB?=1024
export JOBS?=$(shell ${WORKSPACE_DIR}/scripts/guess_jobs.sh ${MEMORY_PER_JOB_MB})


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

wswraptarget:
	time bash -c "${SETUP_SCRIPT}; ${MAKE} ${TARGET}"

wslist:
	@${CMD_PKG_NAME_LIST}

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
	bash -c "${CMD_PKG_NAME_LIST} | xargs -I {} ${MAKE} deplist PKG=\"{}\""
	rm -Rf ${WORKSPACE_DIR}/build/deplist/*.all	${WORKSPACE_DIR}/build/deplist/ccws.list
	cat ${WORKSPACE_DIR}/build/deplist/* | sort | uniq > ${WORKSPACE_DIR}/build/deplist/ccws.deps.all
	${MAKE} rosinstall_extend PKG_LIST="${WORKSPACE_DIR}/build/deplist/ccws.deps.all"


# generic test target, it is recommended to use more specific targets below
wstest_generic:
	${CMD_PKG_NAME_LIST} | xargs -I '{}' sh -c "${MAKE} ${TEST_TARGET} PKG={} || exit ${EXIT_STATUS}"

# stops on first error
wstest_faststop:
	${MAKE} wstest_generic TEST_TARGET=test EXIT_STATUS=255

# stops on first error
wsctest_faststop:
	${MAKE} wstest_generic TEST_TARGET=ctest EXIT_STATUS=255

wstest:
	${MAKE} --quiet wstest_generic TEST_TARGET=test EXIT_STATUS=1

wsctest:
	${MAKE} --quiet wstest_generic TEST_TARGET=ctest EXIT_STATUS=1


##
## Package targets
##

assert_PKG_arg_must_be_specified:
	test "${PKG}" != ""

build:
	${MAKE} wswraptarget TARGET=private_build

# --log-level DEBUG
private_build: assert_PKG_arg_must_be_specified wsprepare_build
	mkdir -p "${CCWS_BUILD_DIR}"
	${CCWS_BUILD_WRAPPER} colcon \
		--log-base build/log/${PROFILE} \
		build \
		--merge-install \
		--base-paths ${WORKSPACE_DIR}/src/ \
		--build-base build/${PROFILE} \
		--install-base "${CCWS_INSTALL_DIR_BUILD}" \
		--cmake-args -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TOOLCHAIN_FILE}" \
		--packages-up-to ${PKG} \
		&& cp ${WORKSPACE_DIR}/scripts/install/setup.bash "${CCWS_INSTALL_DIR_BUILD}/"


# this target uses colcon and unlike `ctest` target does not respect `--output-on-failure`
test: assert_PKG_arg_must_be_specified
	time bash -c "${SETUP_SCRIPT}; \
		colcon \
		--log-base build/log/${PROFILE} \
		test \
		--merge-install \
		--ctest-args --output-on-failure -j ${JOBS} \
		--build-base build/${PROFILE} \
		--install-base \"\$${CCWS_INSTALL_DIR_BUILD}\" \
		--base-paths ${WORKSPACE_DIR}/src/ \
		--test-result-base build/log/${PROFILE}/testing \
		--packages-select ${PKG}"
	${MAKE} showtestresults

ctest: assert_PKG_arg_must_be_specified
	time bash -c "${SETUP_SCRIPT}; \
		mkdir -p \"\$${CCWS_ARTIFACTS_DIR}/\$${PROFILE}\"; \
		cd build/${PROFILE}/${PKG}; \
		time ctest --output-on-failure --output-log \"\$${CCWS_ARTIFACTS_DIR}/\$${PROFILE}/ctest_${PKG}.log\" -j ${JOBS}"
	${MAKE} showtestresults

showtestresults: assert_PKG_arg_must_be_specified
	# shows fewer tests
	colcon --log-base /dev/null test-result --all --test-result-base ${WORKSPACE_DIR}/build/${PROFILE}/${PKG}
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
	@${CMD_PKG_NAME_LIST} --packages-up-to ${PKG} | xargs ${CMD_PKG_INFO} --packages-select

# generate list of dependencies which are not present in the workspace
deplist: assert_PKG_arg_must_be_specified
	mkdir -p ${WORKSPACE_DIR}/build/deplist
	${CMD_PKG_NAME_LIST} | sort > ${WORKSPACE_DIR}/build/deplist/ccws.list
	${MAKE} --quiet info_with_deps \
		| grep '\(build:\)\|\(run:\)\|\(test:\)' \
		| sed -e 's/build://' -e 's/run://' -e 's/test://' -e 's/ /\n/g' \
		| sort | uniq | grep -v '^$$' > ${WORKSPACE_DIR}/build/deplist/${PKG}.all
	# remove packages that are already in the workspace
	comm -13 ${WORKSPACE_DIR}/build/deplist/ccws.list ${WORKSPACE_DIR}/build/deplist/${PKG}.all > ${WORKSPACE_DIR}/build/deplist/${PKG}

dep_to_rosinstall: deplist
	${MAKE} rosinstall_extend PKG_LIST="${WORKSPACE_DIR}/build/deplist/${PKG}"

rosinstall_extend:
	bash -c "${SETUP_SCRIPT}; cat ${PKG_LIST} | paste -s -d ' ' \
		| xargs rosinstall_generator --deps --rosdistro \$${ROS_DISTRO} > ${WORKSPACE_DIR}/build/deplist/${PKG}.rosinstall"
	cd src; wstool merge -y ${WORKSPACE_DIR}/build/deplist/${PKG}.rosinstall


##
## Other targets
##

help:
	@grep -v "^	" Makefile | grep -v "^ " | grep -v "^$$" | grep -v "^\."

.PHONY: build clean test install
