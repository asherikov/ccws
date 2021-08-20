rosdep_%:
	${MAKE} wswraptarget TARGET="private_$@"

private_rosdep_init:
	mkdir -p "${CCWS_PROFILE_DIR}/rosdep"
	mkdir -p "${ROS_HOME}"
	ln --symbolic --force --no-target-directory "${CCWS_PROFILE_DIR}/rosdep" "${ROS_HOME}/rosdep"

private_rosdep_resolve: private_rosdep_init deplist
	test -d '${ROS_HOME}/rosdep/sources.cache/' || rosdep update
	cat '${WORKSPACE_DIR}/build/deplist/${PKG}' | xargs rosdep resolve \
		| grep -v '^#' | sed 's/ /\n/g' | grep -v '^$$' | sort | uniq > '${WORKSPACE_DIR}/build/deplist/${PKG}.deb'

private_rosdep_install: private_rosdep_resolve
	cat '${WORKSPACE_DIR}/build/deplist/${PKG}.deb' | xargs sudo ${CCWS_CHROOT} ${APT_INSTALL}
