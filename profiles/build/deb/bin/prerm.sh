#!/bin/bash

set -e
shopt -s nullglob dotglob

SCRIPT="${CCWS_DEBIAN_DIR}/prerm"
VERSION=$(cat "${CCWS_DEB_INFO_DIR}/version_hash.txt")
MESSAGE="${VENDOR}: Removing '${CCWS_PKG_FULL_NAME} / ${VERSION}'"

cat > "${SCRIPT}" <<EOF
#!/bin/sh
set -e

for PRERM in ${CCWS_INSTALL_DIR_HOST}/share/*/prerm/*.sh;
do
    if [ -f "\${PRERM}" ]
    then
        echo "Running \${PRERM}"
        "\${PRERM}"
    fi
done
EOF

for EXTRA_SCRIPT in "${CCWS_DEBIAN_PRERM_DIR}"/*
do
    echo "echo 'Running $(basename ${EXTRA_SCRIPT})'" >> ${SCRIPT}
    cat "${EXTRA_SCRIPT}" >> ${SCRIPT}
done

cat >> "${SCRIPT}" <<EOF
logger "${MESSAGE}"
echo "${MESSAGE}"
EOF

chmod +x "${SCRIPT}"

