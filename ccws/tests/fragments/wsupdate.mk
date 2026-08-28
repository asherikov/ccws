test:
	${MAKE} wsupdate_shallow
	${MAKE} -n wsupdate_pkgs 2>&1 | grep -qv -- '--prefer-version '
	${MAKE} -n wsupdate_pkgs CCWS_PREFER_VERSION=main 2>&1 | grep -qF -- '--prefer-version main'
	${MAKE} -n wsupdate_pkgs_shallow 2>&1 | grep -qv -- '--prefer-version '
	${MAKE} -n wsupdate_pkgs_shallow CCWS_PREFER_VERSION=v1.0 2>&1 | grep -qF -- '--prefer-version v1.0'
	${MAKE} -n wsupdate_pkgs_shallow_rebase 2>&1 | grep -qv -- '--prefer-version '
	${MAKE} -n wsupdate_pkgs_shallow_rebase CCWS_PREFER_VERSION=release 2>&1 | grep -qF -- '--prefer-version release'
