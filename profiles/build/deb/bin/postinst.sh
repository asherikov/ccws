#!/bin/bash

SCRIPT="${CCWS_INSTALL_DIR_BUILD_ROOT}/DEBIAN/postinst"
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

logger "${MESSAGE}"
echo "${MESSAGE}"
EOF

chmod +x "${SCRIPT}"

