DEPLIST_DIR=${WORKSPACE_DIR}/build/${BUILD_PROFILE}_dep/
DEPLIST_FILE=${DEPLIST_DIR}/deps_${PKG}


dep_%:
	${MAKE} wswraptarget TARGET="private_$@"

private_dep_resolve: private_dep_list
	mkdir -p '${CCWS_BUILD_PROFILE_DIR}/rosdep'
	test -d '${CCWS_BUILD_PROFILE_DIR}/rosdep/sources.cache/' || env ROS_HOME='${CCWS_BUILD_PROFILE_DIR}' rosdep update
	cat '${DEPLIST_FILE}' | env ROS_HOME='${CCWS_BUILD_PROFILE_DIR}' xargs rosdep resolve \
		| grep -v '^#' | sed 's/ /\n/g' | grep -v '^$$' | sort | uniq > '${DEPLIST_FILE}.deb'

private_dep_install: private_dep_resolve
	cat '${DEPLIST_FILE}.deb' | xargs sudo ${CCWS_CHROOT} ${APT_INSTALL}

private_dep_to_repolist: private_dep_list
	bash -c "${SETUP_SCRIPT}; cat '${DEPLIST_FILE}' | paste -s -d ' ' \
		| xargs rosinstall_generator --deps > ${DEPLIST_FILE}.rosinstall"
	cd src; wstool merge -y ${DEPLIST_FILE}.rosinstall

# generate list of dependencies which are not present in the workspace
private_dep_list:
	mkdir -p ${DEPLIST_DIR}
	${CMD_PKG_NAME_LIST} | sort > ${DEPLIST_DIR}/ccws.list
	${MAKE} --quiet private_info_with_deps \
		| grep '\(build:\)\|\(run:\)\|\(test:\)' \
		| sed -e 's/build://' -e 's/run://' -e 's/test://' -e 's/ /\n/g' \
		| sort | uniq | grep -v '^$$' > ${DEPLIST_FILE}.all
	# remove packages that are already in the workspace
	comm -13 ${DEPLIST_DIR}/ccws.list ${DEPLIST_FILE}.all > ${DEPLIST_FILE}


# `colcon info --packages-up-to <pkg>` is buggy -> https://github.com/colcon/colcon-core/issues/443
private_info_with_deps:
	@test -z "${PKG}" || ${CMD_PKG_NAME_LIST} --packages-up-to ${PKG} | xargs ${CMD_PKG_INFO} --packages-select
	@test -n "${PKG}" || ${CMD_PKG_NAME_LIST} | xargs ${CMD_PKG_INFO} --packages-select

