CCWS_SSH_KEY?=${CCWS_DIR}/ssh/id_rsa

ssh_keygen:
	ssh-keygen -f "${CCWS_SSH_KEY}"

ssh_keygen_if_none:
	test -f "${CCWS_SSH_KEY}" || ${MAKE} ssh_keygen
