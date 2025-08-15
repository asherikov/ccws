#!/bin/bash

set -e
set -o pipefail

cat > "${CCWS_DEBIAN_DIR}/control" <<EOF
Package: $(echo "${CCWS_PKG_FULL_NAME}" | sed 's/_/-/g' || ERR=YES)
Version: $(sed 's/_/-/g' < "${CCWS_DEB_INFO_DIR}/version_hash.txt" || ERR=YES)
Architecture: ${CCWS_DEB_ARCH}
Maintainer: ${AUTHOR} <${EMAIL}>
Description: ${VENDOR} ${PKG}
Depends: $(paste -s -d ',' < "${DEPLIST_FILE}.deb" || ERR=YES)
Installed-Size: $(du -s "${CCWS_INSTALL_DIR_BUILD_ROOT}" | cut -f 1 || ERR=YES)
EOF

# errors in process subsitution are lost
# https://stackoverflow.com/questions/79657285/how-to-detect-errors-with-process-substitution
test "${ERR}" != "YES" || exit 255
