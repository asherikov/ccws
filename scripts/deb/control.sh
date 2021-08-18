#!/bin/bash

if [ -z "${CCWS_TRIPLE_ARCH}" ]
then
    ${CCWS_TRIPLE_ARCH}
fi

case "${CCWS_TRIPLE_ARCH}" in
    # fixes 'package architecture (aarch64) does not match system (arm64)', deb
    # architecture naming conventions are different
    aarch64) CCWS_DEB_ARCH=arm64;;
    x86_64) CCWS_DEB_ARCH=amd64;;

    *) CCWS_DEB_ARCH=${CCWS_TRIPLE_ARCH};;
esac


cat > "${CCWS_INSTALL_DIR_HOST_ROOT}/DEBIAN/control" <<EOF
Package: $(echo "${CCWS_PKG_FULL_NAME}" | sed 's/_/-/g')
Version: ${CCWS_DEB_VERSION}
Architecture: ${CCWS_DEB_ARCH}
Maintainer: ${AUTHOR} <${EMAIL}>
Description: ${CCWS_VENDOR_ID} ${PKG}
Depends: $(paste -s -d ',' < "${WORKSPACE_DIR}/build/deplist/${PKG}.deb")
EOF

