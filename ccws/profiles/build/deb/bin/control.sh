#!/bin/bash

set -e
set -o pipefail

# Parameters may be overridden to generate control files for subpackages, see
# 'private_deb_pack_subpackage' in targets.mk
CCWS_DEB_PKG_NAME=${CCWS_DEB_PKG_NAME:-${CCWS_PKG_FULL_NAME}}
# deb package names must not contain underscores
CCWS_DEB_PKG_NAME=$(echo "${CCWS_DEB_PKG_NAME}" | sed 's/_/-/g')
CCWS_DEB_PKG_DIR=${CCWS_DEB_PKG_DIR:-${CCWS_INSTALL_DIR_BUILD_ROOT}}
CCWS_DEB_PKG_ARCH=${CCWS_DEB_PKG_ARCH:-${CCWS_DEB_ARCH}}
CCWS_DEB_PKG_DESCRIPTION=${CCWS_DEB_PKG_DESCRIPTION:-${VENDOR} ${PKG}}

# an explicitly provided (possibly empty) value overrides the resolved
# dependency list, an empty value generates no 'Depends' field at all
if [ -n "${CCWS_DEB_PKG_DEPENDS+x}" ]
then
    DEPENDS=${CCWS_DEB_PKG_DEPENDS}
else
    DEPENDS=$(paste -s -d ',' < "${DEPLIST_FILE}.deb" || ERR=YES)
fi

{
    printf 'Package: %s\n' "${CCWS_DEB_PKG_NAME}"
    printf 'Version: %s\n' "$(sed 's/_/-/g' < "${CCWS_DEB_INFO_DIR}/version_hash.txt" || ERR=YES)"
    printf 'Architecture: %s\n' "${CCWS_DEB_PKG_ARCH}"
    printf 'Maintainer: %s <%s>\n' "${AUTHOR}" "${EMAIL}"
    printf 'Description: %s\n' "${CCWS_DEB_PKG_DESCRIPTION}"
    test -z "${DEPENDS}" || printf 'Depends: %s\n' "${DEPENDS}"
    printf 'Installed-Size: %s\n' "$(du -s "${CCWS_DEB_PKG_DIR}" | cut -f 1 || ERR=YES)"
} > "${CCWS_DEBIAN_DIR}/control"

# errors in process subsitution are lost
# https://stackoverflow.com/questions/79657285/how-to-detect-errors-with-process-substitution
test "${ERR}" != "YES" || exit 255
