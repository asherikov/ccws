#!/bin/bash

case "${CCWS_TRIPLE_ARCH}" in
    # fixes 'package architecture (aarch64) does not match system (arm64)', deb
    # architecture naming conventions are different
    aarch64) CCWS_DEB_ARCH=arm64;;
    x86_64) CCWS_DEB_ARCH=amd64;;

    *) CCWS_DEB_ARCH=${CCWS_TRIPLE_ARCH};;
esac

# TODO no need to depend on build dependencies
cat > "${CCWS_INSTALL_DIR_BUILD_ROOT}/DEBIAN/control" <<EOF
Package: $(echo "${CCWS_PKG_FULL_NAME}" | sed 's/_/-/g')
Version: $(sed 's/_/-/g' < "${CCWS_DEB_INFO_DIR}/version.txt")
Architecture: ${CCWS_DEB_ARCH}
Maintainer: ${AUTHOR} <${EMAIL}>
Description: ${VENDOR} ${PKG}
Depends: $(paste -s -d ',' < "${WORKSPACE_DIR}/build/${PROFILE}_dep/deps_${PKG}.deb")
EOF

