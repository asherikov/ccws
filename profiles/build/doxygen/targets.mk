bp_doxygen_install_build: bp_common_install_build
	sudo ${APT_INSTALL} doxygen graphviz

doxclean:
	bash -c "${SETUP_SCRIPT}; \
		rm -Rf \$${CCWS_DOXYGEN_OUTPUT_DIR}/doxygen; \
		rm -Rf \$${CCWS_DOXYGEN_WORKING_DIR}"

bp_doxygen_build:
	test "${PKG}" = "" || ${MAKE} dox
	test "${PKG}" != "" || ${MAKE} doxall

assert_doxygen_installed:
	type doxygen > /dev/null

doxall: doxclean assert_doxygen_installed
	bash -c "${SETUP_SCRIPT}; \
        ${CMD_PKG_NAME_LIST} | xargs -I {} bash -c '${MAKE} dox PKG={}' || true; \
		${CMD_PKG_GRAPH} | sed 's@  \"\\(.*\\)\";@  "\\1" [URL=\"./\\1/index.html\"];@' | dot -Tsvg > \$${CCWS_DOXYGEN_OUTPUT_DIR}/pkg_dependency_graph.svg; \
        cd \$${CCWS_DOXYGEN_OUTPUT_DIR}; \
        cat \$${CCWS_DOXYGEN_CONFIG_DIR}/index_header.html > \$${CCWS_DOXYGEN_OUTPUT_DIR}/index.html; \
		echo '<ul>' >> index.html; \
		find ./ -mindepth 2 -maxdepth 2 -name 'index.html' | sort \
			| sed -e 's|./\(.*\)/index.html|<li><a href=\"./\1/index.html\">\1</a></li>|' >> index.html; \
		echo '</ul><h3>Summary</h3><ul><li>packages: ' >> index.html; \
		${CMD_PKG_NAME_LIST} | wc -l >> index.html; \
		echo '</li>' >> index.html; \
        cat \$${CCWS_DOXYGEN_CONFIG_DIR}/index_footer.html >> \$${CCWS_DOXYGEN_OUTPUT_DIR}/index.html"

# documentation for dependencies should be generated first for cross linking
dox: assert_PKG_arg_must_be_specified assert_doxygen_installed
	# generate Doxyfile
	bash -c "${SETUP_SCRIPT}; \
		rm -Rf \$${CCWS_DOXYGEN_OUTPUT_DIR}/${PKG} \$${CCWS_DOXYGEN_WORKING_DIR}/${PKG}; \
        mkdir -p \$${CCWS_DOXYGEN_WORKING_DIR}/${PKG}; \
        cp \$${CCWS_DOXYGEN_CONFIG_DIR}/Doxyfile \$${CCWS_DOXYGEN_WORKING_DIR}/${PKG}/Doxyfile; \
        sed -i -e 's/@@PKG@@/${PKG}/' \$${CCWS_DOXYGEN_WORKING_DIR}/${PKG}/Doxyfile; \
        ${CMD_PKG_NAME_LIST} --packages-up-to ${PKG} --packages-skip ${PKG} \
            | xargs -I {} find \$${CCWS_DOXYGEN_WORKING_DIR} -mindepth 2 -maxdepth 2 -ipath '*{}/Doxyfile.append' >> \$${CCWS_DOXYGEN_WORKING_DIR}/${PKG}/deps; \
        cat \$${CCWS_DOXYGEN_WORKING_DIR}/${PKG}/deps | xargs -I {} cat {} >> \$${CCWS_DOXYGEN_WORKING_DIR}/${PKG}/Doxyfile; \
        mkdir -p \$${CCWS_DOXYGEN_OUTPUT_DIR}/${PKG}; \
		${CMD_PKG_GRAPH} --packages-up-to ${PKG} \
			| sed 's@  \"\\(.*\\)\";@  "\\1" [URL=\"../\\1/index.html\"];@' | dot -Tsvg > \$${CCWS_DOXYGEN_OUTPUT_DIR}/${PKG}/pkg_dependency_graph.svg; \
        cd `${CMD_PKG_LIST} | grep '^${PKG}[[:blank:]]' | sed 's/.*\t\(.*\)\t.*/\1/'`; \
        echo 'TAGFILES+=\"\$$(CCWS_DOXYGEN_WORKING_DIR)/${PKG}/tags.xml=../${PKG}/\"' > \$${CCWS_DOXYGEN_WORKING_DIR}/${PKG}/Doxyfile.append; \
        find ~+ -path '*include/*' -type d | sed -e 's/\(.*\)/INCLUDE_PATH+=\"\1\"/' >> \$${CCWS_DOXYGEN_WORKING_DIR}/${PKG}/Doxyfile.append; \
        doxygen \$${CCWS_DOXYGEN_WORKING_DIR}/${PKG}/Doxyfile"

