bp_doxygen_install_build: install_ccws_deps
	sudo ${APT_INSTALL} doxygen graphviz pandoc

doxclean:
	bash -c "${SETUP_SCRIPT}; \
		rm -Rf \$${CCWS_DOXYGEN_OUTPUT_DIR}; \
		rm -Rf \$${CCWS_DOXYGEN_WORKING_DIR}"

bp_doxygen_build: doxclean assert_doxygen_installed
	bash -c "${SETUP_SCRIPT}; \
		${MAKE_QUIET} wslist | xargs -I {} bash -c '${MAKE} dox PKG={}' || true; \
		${MAKE_QUIET} wslist | wc -l > \$${CCWS_DOXYGEN_WORKING_DIR}/package_num; \
		${MAKE_QUIET} graph | sed 's@  \"\\(.*\\)\";@  \"\\1\" [URL=\"./\\1/index.html\"];@' | dot -Tsvg > \$${CCWS_DOXYGEN_OUTPUT_DIR}/pkg_dependency_graph.svg; \
		${MAKE_QUIET} wsstatus > \$${CCWS_DOXYGEN_WORKING_DIR}/wsstatus; \
        cd \$${CCWS_DOXYGEN_OUTPUT_DIR}; \
		cp \$${CCWS_PRIMARY_BUILD_PROFILE_DIR}/pandoc/* ./; \
		test ! -f \$${CCWS_SOURCE_DIR}/README.md || cat \$${CCWS_SOURCE_DIR}/README.md > index.md; \
        cat \$${CCWS_DOXYGEN_CONFIG_DIR}/index_header.md >> index.md; \
		find ./ -mindepth 2 -maxdepth 2 -name 'index.html' | sort \
			| sed -e 's=./\(.*\)/index.html=| [\1](./\1/index.html) | [graph](./\1/pkg_dependency_graph.svg) | [graph](./\1/pkg_reverse_dependency_graph.svg) |=' >> index.md; \
		echo -e '\nTotal number of packages: ' >> index.md; \
		cat \$${CCWS_DOXYGEN_WORKING_DIR}/package_num >> index.md; \
		echo -e '\nWorkspace status\n-----\n:::{.wide}\n\`\`\`' >> index.md; \
		cat \$${CCWS_DOXYGEN_WORKING_DIR}/wsstatus >> index.md; \
		echo -e '\`\`\`\n:::\n' >> index.md; \
        cat \$${CCWS_DOXYGEN_CONFIG_DIR}/index_footer.md >> index.md; \
		pandoc index.md --output index.html --table-of-contents --number-sections --to html5+smart --template=template.html5 --css theme.css --css skylighting-solarized-theme.css --wrap=none --variable=date:\"DATE: `date '+%Y-%m-%d'`\" --metadata title=\"\$${VENDOR}\""

assert_doxygen_installed:
	type doxygen > /dev/null


# documentation for dependencies should be generated first for cross linking
dox: assert_PKG_arg_must_be_specified assert_doxygen_installed
	# generate Doxyfile
	bash -c "${SETUP_SCRIPT}; \
		rm -Rf \$${CCWS_DOXYGEN_OUTPUT_DIR}/${PKG} \$${CCWS_DOXYGEN_WORKING_DIR}/${PKG}; \
        mkdir -p \$${CCWS_DOXYGEN_WORKING_DIR}/${PKG}; \
        cp \$${CCWS_DOXYGEN_CONFIG_DIR}/Doxyfile \$${CCWS_DOXYGEN_WORKING_DIR}/${PKG}/Doxyfile; \
        sed -i -e 's/@@PKG@@/${PKG}/' \$${CCWS_DOXYGEN_WORKING_DIR}/${PKG}/Doxyfile; \
        sed -i -e 's/@@JOBS@@/${JOBS}/' \$${CCWS_DOXYGEN_WORKING_DIR}/${PKG}/Doxyfile; \
        ${CMD_PKG_NAME_LIST} --packages-up-to ${PKG} --packages-skip ${PKG} \
            | xargs -I {} find \$${CCWS_DOXYGEN_WORKING_DIR} -mindepth 2 -maxdepth 2 -ipath '*{}/Doxyfile.append' >> \$${CCWS_DOXYGEN_WORKING_DIR}/${PKG}/deps; \
        cat \$${CCWS_DOXYGEN_WORKING_DIR}/${PKG}/deps | xargs -I {} cat {} >> \$${CCWS_DOXYGEN_WORKING_DIR}/${PKG}/Doxyfile; \
        mkdir -p \$${CCWS_DOXYGEN_OUTPUT_DIR}/${PKG}; \
		${MAKE_QUIET} graph | sed 's@  \"\\(.*\\)\";@  \"\\1\" [URL=\"../\\1/index.html\"];@' | dot -Tsvg > \$${CCWS_DOXYGEN_OUTPUT_DIR}/${PKG}/pkg_dependency_graph.svg; \
		${MAKE_QUIET} graph_reverse | sed 's@  \"\\(.*\\)\";@  \"\\1\" [URL=\"../\\1/index.html\"];@' | dot -Tsvg > \$${CCWS_DOXYGEN_OUTPUT_DIR}/${PKG}/pkg_reverse_dependency_graph.svg; \
        cd `${CMD_PKG_LIST} | grep '^${PKG}[[:blank:]]' | sed 's/.*\t\(.*\)\t.*/\1/'`; \
        echo 'TAGFILES+=\"\$$(CCWS_DOXYGEN_WORKING_DIR)/${PKG}/tags.xml=../${PKG}/\"' > \$${CCWS_DOXYGEN_WORKING_DIR}/${PKG}/Doxyfile.append; \
        find ~+ -path '*include/*' -type d | sed -e 's/\(.*\)/INCLUDE_PATH+=\"\1\"/' >> \$${CCWS_DOXYGEN_WORKING_DIR}/${PKG}/Doxyfile.append; \
        doxygen \$${CCWS_DOXYGEN_WORKING_DIR}/${PKG}/Doxyfile"

bp_doxygen_gh_pages:
	cd "${GH_PAGES_DIR}" \
		&& git fetch --all \
		&& git checkout gh-pages \
		&& find ./ -not -name '.*' -maxdepth 1 | xargs rm -rf \
		&& cp -r ${CCWS_ARTIFACTS_DIR}/* ./ \
		&& git add -f * \
		&& git commit -a -m "${MESSAGE}" \
		&& git push
