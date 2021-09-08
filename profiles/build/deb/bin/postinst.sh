#!/bin/bash

SCRIPT="${CCWS_INSTALL_DIR_BUILD_ROOT}/DEBIAN/postinst"
VERSION=$(cat "${CCWS_DEB_INFO_DIR}/version.txt")
MESSAGE="${VENDOR}: Installation of '${CCWS_PKG_FULL_NAME} / ${VERSION}' completed"

cat > "${SCRIPT}" <<EOF
#!/bin/sh
logger "${MESSAGE}"
echo "${MESSAGE}"
EOF

chmod +x "${SCRIPT}"

