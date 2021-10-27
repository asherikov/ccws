#!/bin/bash

# TODO no need to depend on build dependencies
cat > "${CCWS_INSTALL_DIR_BUILD_ROOT}/DEBIAN/control" <<EOF
Package: $(echo "${CCWS_PKG_FULL_NAME}" | sed 's/_/-/g')
Version: $(sed 's/_/-/g' < "${CCWS_DEB_INFO_DIR}/version_hash.txt")
Architecture: ${CCWS_DEB_ARCH}
Maintainer: ${AUTHOR} <${EMAIL}>
Description: ${VENDOR} ${PKG}
Depends: $(paste -s -d ',' < "${WORKSPACE_DIR}/build/${BUILD_PROFILE}_dep/deps_${PKG}.deb")
EOF

