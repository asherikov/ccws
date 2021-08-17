#!/bin/bash

SCRIPT="${CCWS_INSTALL_DIR_HOST_ROOT}/DEBIAN/postinst"
MESSAGE="${CCWS_VENDOR_ID}: Installation of '${CCWS_PKG_FULL_NAME} / ${CCWS_DEB_VERSION}' completed"

cat > "${SCRIPT}" <<EOF
#!/bin/sh
logger "${MESSAGE}"
echo "${MESSAGE}"
EOF

chmod +x "${SCRIPT}"

