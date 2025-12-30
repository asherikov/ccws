bp_doxygen_install_build: install_ccws_deps install_python3
	sudo ${APT_INSTALL} doxygen graphviz pandoc
	-${PIPX_UNINSTALL} hiearch
	${PIPX_INSTALL} hiearch

doxclean:
	bash -c "${SETUP_SCRIPT} \
		&& rm -Rf \$${CCWS_DOXYGEN_OUTPUT_DIR} \
		&& rm -Rf \$${CCWS_DOXYGEN_WORKING_DIR}"

bp_doxygen_build: doxclean assert_doxygen_installed
	-${MAKE_QUIET} wslist | xargs -I {} bash -c "${MAKE} dox PKG={}"
	${MAKE} wswraptarget TARGET=private_bp_doxygen_build_index

private_bp_doxygen_build_index:
	${MAKE_QUIET} graph > ${CCWS_DOXYGEN_WORKING_DIR}/pkg_dependency_graph.dot
	cd ${CCWS_DOXYGEN_WORKING_DIR} && hiearch -o ./ pkg_dependency_graph.dot ${CCWS_DOXYGEN_CONFIG_DIR}/hiearch.yaml
	cp ${CCWS_DOXYGEN_WORKING_DIR}/packages*.svg ${CCWS_DOXYGEN_OUTPUT_DIR}/
	-cat ${CCWS_SOURCE_DIR}/README.md ${CCWS_DOXYGEN_CONFIG_DIR}/index_header.md > ${CCWS_DOXYGEN_WORKING_DIR}/index.md
	find ${CCWS_DOXYGEN_OUTPUT_DIR} -mindepth 2 -maxdepth 2 -name 'index.html' -printf '%P\n' | sort \
		| sed -e 's=\(.*\)/index.html=| [\1](./\1/index.html) | [graph](./packages_\1_recursive_all.svg) |=' >> ${CCWS_DOXYGEN_WORKING_DIR}/index.md
	printf '\nTotal number of packages: %b\n' `${MAKE_QUIET} wslist | wc -l` >> ${CCWS_DOXYGEN_WORKING_DIR}/index.md
	printf '\nWorkspace status\n-----\n:::{.wide}\n```\n' >> ${CCWS_DOXYGEN_WORKING_DIR}/index.md
	${MAKE_QUIET} wsstatus >> ${CCWS_DOXYGEN_WORKING_DIR}/index.md
	cat ${CCWS_DOXYGEN_CONFIG_DIR}/index_footer.md >> ${CCWS_DOXYGEN_WORKING_DIR}/index.md
	cp ${CCWS_DOXYGEN_CONFIG_DIR}/pandoc/*.css ${CCWS_DOXYGEN_OUTPUT_DIR}/
	cd ${CCWS_DOXYGEN_OUTPUT_DIR}/ \
		&& pandoc ${CCWS_DOXYGEN_WORKING_DIR}/index.md \
			--output index.html --table-of-contents --number-sections --to html5+smart \
			--template=${CCWS_DOXYGEN_CONFIG_DIR}/pandoc/template.html5 \
			--css theme.css --css skylighting-solarized-theme.css --wrap=none \
			--variable=date:"DATE: `date '+%Y-%m-%d'`" --metadata title="${VENDOR}"


assert_doxygen_installed:
	type doxygen > /dev/null


# documentation for dependencies should be generated first for cross linking
dox: assert_PKG_arg_must_be_specified assert_doxygen_installed
	${MAKE} wswraptarget TARGET=private_bp_doxygen_dox

private_bp_doxygen_dox:
	rm -Rf ${CCWS_DOXYGEN_OUTPUT_DIR}/${PKG} ${CCWS_DOXYGEN_WORKING_DIR}/${PKG}
	mkdir -p ${CCWS_DOXYGEN_OUTPUT_DIR}/${PKG} ${CCWS_DOXYGEN_WORKING_DIR}
	cp -r ${CCWS_DOXYGEN_CONFIG_DIR}/working_dir ${CCWS_DOXYGEN_WORKING_DIR}/${PKG}
	sed -i -e "s/@@PKG@@/${PKG}/" -e "s/@@JOBS@@/${JOBS}/" ${CCWS_DOXYGEN_WORKING_DIR}/${PKG}/*
	-${CMD_PKG_NAME_LIST} --packages-up-to ${PKG} --packages-skip ${PKG} \
		| xargs --no-run-if-empty -I {} cat "${CCWS_DOXYGEN_WORKING_DIR}/{}/Doxyfile.append" >> ${CCWS_DOXYGEN_WORKING_DIR}/${PKG}/Doxyfile
	cd `${CMD_PKG_LIST} | grep "^${PKG}[[:blank:]]" | sed "s/.*\t\(.*\)\t.*/\1/"` \
		&& find ~+ -path "*include/*" -type d | sed -e "s/\(.*\)/INCLUDE_PATH+=\"\1\"/" >> ${CCWS_DOXYGEN_WORKING_DIR}/${PKG}/Doxyfile.append \
		&& doxygen ${CCWS_DOXYGEN_WORKING_DIR}/${PKG}/Doxyfile

bp_doxygen_gh_pages:
	cd "${GH_PAGES_DIR}" \
		&& git fetch --all \
		&& git checkout gh-pages \
		&& find ./ -not -name '.*' -maxdepth 1 | xargs rm -rf \
		&& cp -r ${CCWS_ARTIFACTS_DIR}/* ./ \
		&& git add -f * \
		&& git commit -a -m "${MESSAGE}" \
		&& git push
