#!/bin/bash

SCRIPT="${CCWS_INSTALL_DIR_BUILD_ROOT}/DEBIAN/preinst"
VERSION=$(cat "${CCWS_DEB_INFO_DIR}/version.txt")
MESSAGE="${VENDOR}: Installing '${CCWS_PKG_FULL_NAME} / ${VERSION}'"

cat > "${SCRIPT}" <<EOF
#!/bin/sh
logger "${MESSAGE}"
echo "${MESSAGE}"
EOF

chmod +x "${SCRIPT}"
