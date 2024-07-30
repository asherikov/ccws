#!/bin/bash

set -e
shopt -s nullglob dotglob

SCRIPT="${CCWS_DEBIAN_DIR}/preinst"
VERSION=$(cat "${CCWS_DEB_INFO_DIR}/version_hash.txt")
MESSAGE="${VENDOR}: Installing '${CCWS_PKG_FULL_NAME} / ${VERSION}'"

cat > "${SCRIPT}" <<EOF
#!/bin/sh
set -e
EOF

for EXTRA_SCRIPT in "${CCWS_DEBIAN_PREINST_DIR}"/*
do
    echo "echo 'Running $(basename ${EXTRA_SCRIPT})'" >> ${SCRIPT}
    cat "${EXTRA_SCRIPT}" >> ${SCRIPT}
done

cat >> "${SCRIPT}" <<EOF
logger "${MESSAGE}"
echo "${MESSAGE}"
EOF

chmod +x "${SCRIPT}"
