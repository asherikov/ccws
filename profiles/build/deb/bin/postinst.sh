#!/bin/bash

set -e
shopt -s nullglob dotglob

SCRIPT="${CCWS_DEBIAN_DIR}/postinst"
VERSION=$(cat "${CCWS_DEB_INFO_DIR}/version_hash.txt")
MESSAGE="${VENDOR}: Installation of '${CCWS_PKG_FULL_NAME} / ${VERSION}' completed"

cat > "${SCRIPT}" <<EOF
#!/bin/sh
set -e

for POSTINST in ${CCWS_INSTALL_DIR_HOST}/share/*/postinst/*.sh;
do
    if [ -f "\${POSTINST}" ]
    then
        echo "Running \${POSTINST}"
        "\${POSTINST}"
    fi
done
EOF

for EXTRA_SCRIPT in "${CCWS_DEBIAN_POSTINST_DIR}"/*
do
    echo "echo 'Running $(basename ${EXTRA_SCRIPT})'" >> ${SCRIPT}
    cat "${EXTRA_SCRIPT}" >> ${SCRIPT}
done

cat >> "${SCRIPT}" <<EOF
logger "${MESSAGE}"
echo "${MESSAGE}"
EOF

chmod +x "${SCRIPT}"

