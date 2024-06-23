bp_doxygen_install_build: bp_common_install_build
	sudo ${APT_INSTALL} doxygen graphviz

doxclean:
	bash -c "${SETUP_SCRIPT}; \
		rm -Rf \$${CCWS_DOXYGEN_OUTPUT_DIR}/doxygen; \
		rm -Rf \$${CCWS_DOXYGEN_WORKING_DIR}"

bp_doxygen_build: doxclean assert_doxygen_installed
	bash -c "${SETUP_SCRIPT}; \
        ${MAKE_QUIET} wslist | xargs -I {} bash -c '${MAKE} dox PKG={}' || true; \
		${MAKE_QUIET} wslist | wc -l > \$${CCWS_DOXYGEN_WORKING_DIR}/package_num; \
		${MAKE_QUIET} graph | sed 's@  \"\\(.*\\)\";@  "\\1" [URL=\"./\\1/index.html\"];@' | dot -Tsvg > \$${CCWS_DOXYGEN_OUTPUT_DIR}/pkg_dependency_graph.svg; \
        cd \$${CCWS_DOXYGEN_OUTPUT_DIR}; \
        cat \$${CCWS_DOXYGEN_CONFIG_DIR}/index_header.html > index.html; \
		echo '<table border="1">' >> index.html; \
		find ./ -mindepth 2 -maxdepth 2 -name 'index.html' | sort \
			| sed -e 's|./\(.*\)/index.html|<tr><td><a href=\"./\1/index.html\">\1</a></td><td><a href=\"./\1/pkg_dependency_graph.svg\">dependency graph</a></td><tr>|' >> index.html; \
		echo '</table><h3>Summary</h3><ul><li>packages: ' >> index.html; \
		cat \$${CCWS_DOXYGEN_WORKING_DIR}/package_num >> index.html; \
		echo '</li>' >> index.html; \
        cat \$${CCWS_DOXYGEN_CONFIG_DIR}/index_footer.html >> index.html"

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
		${MAKE_QUIET} graph | sed 's@  \"\\(.*\\)\";@  "\\1" [URL=\"../\\1/index.html\"];@' | dot -Tsvg > \$${CCWS_DOXYGEN_OUTPUT_DIR}/${PKG}/pkg_dependency_graph.svg; \
        cd `${CMD_PKG_LIST} | grep '^${PKG}[[:blank:]]' | sed 's/.*\t\(.*\)\t.*/\1/'`; \
        echo 'TAGFILES+=\"\$$(CCWS_DOXYGEN_WORKING_DIR)/${PKG}/tags.xml=../${PKG}/\"' > \$${CCWS_DOXYGEN_WORKING_DIR}/${PKG}/Doxyfile.append; \
        find ~+ -path '*include/*' -type d | sed -e 's/\(.*\)/INCLUDE_PATH+=\"\1\"/' >> \$${CCWS_DOXYGEN_WORKING_DIR}/${PKG}/Doxyfile.append; \
        doxygen \$${CCWS_DOXYGEN_WORKING_DIR}/${PKG}/Doxyfile"

