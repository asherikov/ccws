doxclean:
	bash -c "${SETUP_SCRIPT} \
		&& rm -Rf \$${CCW_DOXYGEN_OUTPUT_DIR}/doxygen \
		&& rm -Rf \$${CCW_DOXYGEN_WORKING_DIR}"

doxall: doxclean
	bash -c "${SETUP_SCRIPT} \
        && colcon list \$${COLCON_LIST_ARGS} | xargs -I {} bash -c '${MAKE} dox PKG={}' || true \
		&& colcon graph --dot | sed 's@  \"\\(.*\\)\";@  "\\1" [URL=\"./\\1/index.html\"];@' | dot -Tsvg > \$${CCW_DOXYGEN_OUTPUT_DIR}/graph.svg \
        && cd \$${CCW_DOXYGEN_OUTPUT_DIR} \
        && cat \$${CCW_DOXYGEN_CONFIG_DIR}/index_header.html > \$${CCW_DOXYGEN_OUTPUT_DIR}/index.html \
		&& find ./ -mindepth 2 -name 'index.html' | sed -e 's|\(.*\)|<li><a href=\"\1\">\1</a></li>|' >> index.html \
        && cat \$${CCW_DOXYGEN_CONFIG_DIR}/index_footer.html >> \$${CCW_DOXYGEN_OUTPUT_DIR}/index.html"

# documentation for dependencies should be generated first for cross linking
dox: assert_PKG_arg_must_be_specified
	# generate Doxyfile
	bash -c "${SETUP_SCRIPT} \
        && rm -Rf \$${CCW_DOXYGEN_WORKING_DIR}/${PKG} \
        && mkdir -p \$${CCW_DOXYGEN_WORKING_DIR}/${PKG} \
        && cp \$${CCW_DOXYGEN_CONFIG_DIR}/Doxyfile \$${CCW_DOXYGEN_WORKING_DIR}/${PKG}/Doxyfile \
        && sed -i -e 's/@@PKG@@/${PKG}/' \$${CCW_DOXYGEN_WORKING_DIR}/${PKG}/Doxyfile \
        && colcon list \$${COLCON_LIST_ARGS} --packages-up-to ${PKG} --packages-skip ${PKG} \
            | xargs -I {} find \$${CCW_DOXYGEN_WORKING_DIR} -type d -mindepth 2 -maxdepth 2 -iname '{}' >> \$${CCW_DOXYGEN_WORKING_DIR}/${PKG}/deps \
        && cat \$${CCW_DOXYGEN_WORKING_DIR}/${PKG}/deps | xargs -I {} cat {} >> \$${CCW_DOXYGEN_WORKING_DIR}/${PKG}/Doxyfile \
        && mkdir -p \$${CCW_DOXYGEN_OUTPUT_DIR} \
        && cd `colcon list | grep ${PKG} | sed 's/.*\t\(.*\)\t.*/\1/'` \
        && echo 'TAGFILES+=\"\$${CCW_DOXYGEN_WORKING_DIR}/${PKG}/tags.xml=../${PKG}/\"' > \$${CCW_DOXYGEN_WORKING_DIR}/${PKG}/Doxyfile.append \
        && find ~+ -path '*include/*' -type d | sed -e 's/\(.*\)/INCLUDE_PATH+=\"\1\"/' >> \$${CCW_DOXYGEN_WORKING_DIR}/${PKG}/Doxyfile.append \
        && doxygen \$${CCW_DOXYGEN_WORKING_DIR}/${PKG}/Doxyfile"

