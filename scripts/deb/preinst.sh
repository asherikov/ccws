#!/bin/bash

SCRIPT="${CCWS_INSTALL_DIR_HOST_ROOT}/DEBIAN/preinst"
MESSAGE="${CCWS_VENDOR_ID}: Installing '${CCWS_PKG_FULL_NAME} / ${CCWS_DEB_VERSION}'"

cat > "${SCRIPT}" <<EOF
#!/bin/sh
logger "${MESSAGE}"
echo "${MESSAGE}"
EOF

chmod +x "${SCRIPT}"
