wslist:
	@test -z "${PKG}" || ${CMD_PKG_NAME_LIST} --packages-up-to ${PKG} | sort
	@test -n "${PKG}" || ${CMD_PKG_NAME_LIST} | sort


# Reset & initialize workspace
wsinit:
	! ${CMD_WSHANDLER} is_source_space
	mkdir -p "${CCWS_SOURCE_DIR}"
	touch "${CCWS_SOURCE_DIR}/.${REPO_LIST_FORMAT}"
	cd ${CCWS_SOURCE_DIR}; bash -c "echo '${REPOS}' | sed -e 's/ \+/ /g' -e 's/ /\n/g' | ${CCWS_XARGS} -P ${JOBS} git clone {}"
	-${MAKE} wsscrape_all
	${MAKE} wsupdate

# Status packages in the workspace
wsstatus:
	cd ${CCWS_SOURCE_DIR}; test ! -d .git || git describe --dirty --broken --all --long --always
	${MAKE} wsstatuspkg

wsstatuspkg:
	@${CMD_WSHANDLER} status

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


add:
	${CMD_WSHANDLER} is_source_space || ${MAKE} wsinit
	bash -c "\
		DIR=\$$(basename ${REPO} | sed -e 's/\.git$$//'); \
		${CMD_WSHANDLER} add git \$${DIR} ${REPO} ${VERSION}"

set_repo_version:
	${CMD_WSHANDLER} set_version_by_url "${REPO}" "${VERSION}"

rm:
	${CMD_WSHANDLER} remove_by_url "${REPO}"

graph:
	@test -z "${PKG}" || ${CMD_PKG_GRAPH} --packages-up-to ${PKG}
	@test -n "${PKG}" || ${CMD_PKG_GRAPH}

graph_reverse: assert_PKG_arg_must_be_specified
	@test -z "${PKG}" || ${CMD_PKG_GRAPH} --packages-above ${PKG}

checkout_src:
	test -z "${SOURCE_SPACE_VERSION}" \
		|| (git clone "${SOURCE_SPACE_REPO}" "${CCWS_SOURCE_DIR}" \
			&& cd "${CCWS_SOURCE_DIR}" \
			&& git checkout "${SOURCE_SPACE_VERSION}" \
			&& git submodule update --init --recursive \
			&& cd "${CCWS_ROOT}" \
			&& (test -z "${PKG_VERSION}" || make set_repo_version REPO="${PKG_REPO}" VERSION="${PKG_VERSION}"))
	test -n "${SOURCE_SPACE_VERSION}" \
		|| (${MAKE} wsinit && ${MAKE} add REPO="${PKG_REPO}" VERSION="${PKG_VERSION}")
	${MAKE} wsupdate_pkgs_shallow

ws_pin:
	test -d ${CCWS_SOURCE_DIR}/.git
	cd ${CCWS_SOURCE_DIR} \
		&& git checkout release \
		&& git merge main \
		&& ${CMD_WSHANDLER} pin \
		&& git commit -m "pin repositories for ${TAG}" .repos \
		&& git tag ${TAG}
