DEPLIST_DIR=${WORKSPACE_DIR}/build/${CCWS_BUILD_PROFILES_ID}/.ccws/dependencies
DEPLIST_FILE=${DEPLIST_DIR}/deps_${PKG_ID}
CCWS_ROSDEP_CACHE=${CCWS_CACHE}/profiles/${CCWS_PRIMARY_BUILD_PROFILE}
CCWS_DEP_TYPE?=all


dep_%:
	${MAKE} wswraptarget TARGET="private_$@"

private_dep_resolve: private_dep_list
	mkdir -p '${CCWS_ROSDEP_CACHE}/rosdep'
	test -d '${CCWS_ROSDEP_CACHE}/rosdep/sources.cache/' || env ROS_HOME='${CCWS_ROSDEP_CACHE}' rosdep update
	${MAKE} private_dep_resolve_list
	${MAKE} private_dep_resolve_deb
	${MAKE} private_dep_resolve_pip

private_dep_resolve_list:
	cat '${DEPLIST_FILE}' | env ROS_HOME='${CCWS_ROSDEP_CACHE}' ${CCWS_XARGS} sh -c "rosdep resolve {} 2> /dev/null | tr '\n' ' ' && echo '\n'" > '${DEPLIST_FILE}.list'

private_dep_resolve_deb:
	cat '${DEPLIST_FILE}.list' \
		| grep '^#apt' | sed -e 's/^#apt//g' -e 's/ /\n/g' | grep -v '^$$' | sort | uniq > '${DEPLIST_FILE}.deb'

private_dep_resolve_pip:
	cat '${DEPLIST_FILE}.list' \
		| grep '^#pip' | sed -e 's/^#pip//g' -e 's/ /\n/g' | grep -v '^$$' | sort | uniq > '${DEPLIST_FILE}.pip'

private_dep_install: private_dep_resolve
	# we dont use "rosdep install" since we need lists of dependencies, e.g., for binary packages
	cat '${DEPLIST_FILE}.deb' | xargs --no-run-if-empty sudo ${CCWS_CHROOT} ${APT_INSTALL}
	cat '${DEPLIST_FILE}.pip' | xargs --no-run-if-empty sudo ${CCWS_CHROOT} ${PIP3_INSTALL}

private_dep_to_repolist:
	mkdir -p ${DEPLIST_DIR}
	${MAKE_QUIET} private_dep_list > ${DEPLIST_FILE}
	bash -c "${SETUP_SCRIPT}; cat '${DEPLIST_FILE}' | paste -s -d ' ' \
		| xargs rosinstall_generator --format ${REPO_LIST_FORMAT} --deps > ${DEPLIST_FILE}.${REPO_LIST_FORMAT}"
	${CMD_WSHANDLER} merge ${DEPLIST_FILE}.${REPO_LIST_FORMAT}

# generate list of dependencies which are not present in the workspace
private_dep_list:
	mkdir -p ${DEPLIST_DIR}
	+${MAKE_QUIET} wslist | sort > ${DEPLIST_DIR}/ccws.list
	+${MAKE_QUIET} private_info_with_deps_${CCWS_DEP_TYPE} | sort | uniq | grep -v '^$$' > ${DEPLIST_FILE}.${CCWS_DEP_TYPE}
	# remove packages that are already in the workspace
	comm -13 ${DEPLIST_DIR}/ccws.list ${DEPLIST_FILE}.${CCWS_DEP_TYPE} > ${DEPLIST_FILE}


# `colcon info --packages-up-to <pkg>` is buggy -> https://github.com/colcon/colcon-core/issues/443
private_info_with_deps:
	${MAKE_QUIET} wslist \
		| xargs colcon --log-base /dev/null info --base-paths ${WORKSPACE_SRC} --packages-select

private_info_with_deps_all:
	${MAKE_QUIET} private_info_with_deps \
		| grep '\(build:\)\|\(run:\)\|\(test:\)' \
		| sed -e 's/build://' -e 's/run://' -e 's/test://' -e 's/ /\n/g'

private_info_with_deps_%:
	${MAKE_QUIET} private_info_with_deps \
		| grep '\(${CCWS_DEP_TYPE}:\)' \
		| sed -e 's/${CCWS_DEP_TYPE}://' -e 's/ /\n/g'
