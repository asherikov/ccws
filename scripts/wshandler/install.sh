#!/bin/sh

set -e

apt_install()
{
    sudo env DEBIAN_FRONTEND=noninteractive apt --yes --no-install-recommends install "$@"
}

snap_install()
{
    sudo snap install "$@"
}


install_tests()
{
    apt_install shellcheck
}

install_deps()
{
    apt_install bash snap
    snap_install yq
}

install_script()
{
    mkdir -p "${HOME}/bin"
    cp wshandler "${HOME}/bin/"
}


case $1 in
    tests)
        install_tests
        install_deps
        ;;
    script)
        install_deps
        install_script
        ;;
    deps)
        install_deps
        ;;
    *)
        ;;
esac
