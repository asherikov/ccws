#!/bin/bash

SCRIPT="${CCWS_INSTALL_DIR_BUILD_ROOT}/DEBIAN/preinst"
VERSION=$(cat "${CCWS_DEB_INFO_DIR}/version_hash.txt")
MESSAGE="${VENDOR}: Installing '${CCWS_PKG_FULL_NAME} / ${VERSION}'"

cat > "${SCRIPT}" <<EOF
#!/bin/sh
set -e

for PREINST in ${CCWS_INSTALL_DIR_HOST}/share/*/preinst/*.sh;
do
    if [ -f "\${PREINST}" ]
    then
        echo "Running \${PREINST}"
        "\${PREINST}"
    fi
done

logger "${MESSAGE}"
echo "${MESSAGE}"
EOF

chmod +x "${SCRIPT}"
