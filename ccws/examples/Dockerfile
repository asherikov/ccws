ARG BASE_IMAGE=ubuntu:noble
FROM ${BASE_IMAGE}

# these would override CCWS commands
ARG APT_INSTALL="env DEBIAN_FRONTEND=noninteractive apt --yes --no-install-recommends install"
ARG PIP3_INSTALL="python3 -m pip install"

ENV PIP_CACHE_DIR=/cache/pip
ENV DEBIAN_FRONTEND=noninteractive

# 1. docker-clean is removed since we mount cache volumes for storing apt data
# 2. Remove EXTERNALLY-MANAGED to work around `externally-managed-environment` pip
#    error in Ubuntu >=24
#    TODO: use venv instead
#    https://askubuntu.com/questions/1465218/pip-error-on-ubuntu-externally-managed-environment-%C3%97-this-environment-is-extern
RUN \
--mount=type=cache,target=/var/cache/apt,sharing=locked \
--mount=type=cache,target=/var/lib/apt/lists/,sharing=locked \
--mount=type=cache,target=/cache/pip,sharing=locked \
    rm /etc/apt/apt.conf.d/docker-clean \
    && apt update \
    && apt upgrade -y \
    && ${APT_INSTALL} neovim screen git ssh python3 \
    && (find /usr/lib/ -name EXTERNALLY-MANAGED | xargs --no-run-if-empty rm) \
    && git config --system --add safe.directory '*' \
    && ssh-keyscan github.com >> /etc/ssh/ssh_known_hosts \
    && ssh-keyscan gitlab.com >> /etc/ssh/ssh_known_hosts

RUN --mount=target=/ccws_docker_context,ro \
    cd /ccws_docker_context \
    && mkdir -p /ccws/workspace \
    && cp -r .clang-format .git .github .gitignore LICENSE Makefile README.md ccws setup.bash /ccws/

WORKDIR /ccws
ENV WORKSPACE_DIR=/ccws/workspace

RUN \
--mount=type=cache,target=/var/cache/apt,sharing=locked \
--mount=type=cache,target=/var/lib/apt/lists/,sharing=locked \
--mount=type=cache,target=/cache/pip,sharing=locked \
    ./ccws/scripts/bootstrap.sh \
    && make ep_install EXEC_PROFILE=valgrind \
    && make bp_install_build BUILD_PROFILE=addr_undef_sanitizers \
    && make bp_install_build BUILD_PROFILE=clangd \
    && make bp_install_build BUILD_PROFILE=cppcheck \
    && make bp_install_build BUILD_PROFILE=cross_raspberry_pi \
    && make bp_install_build BUILD_PROFILE=deb \
    && make bp_install_build BUILD_PROFILE=doxygen \
    && make bp_install_build BUILD_PROFILE=reldebug \
    && make bp_install_build BUILD_PROFILE=scan_build \
    && make bp_install_build BUILD_PROFILE=static_checks \
    && make bp_install_build BUILD_PROFILE=thread_sanitizer
