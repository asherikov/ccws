ARG BASE_IMAGE=ubuntu:jammy
FROM ${BASE_IMAGE}

ARG APT_INSTALL="apt --yes --no-install-recommends install"
ARG PIP3_INSTALL="python3 -m pip install"

ENV PIP_CACHE_DIR=/cache/pip
ENV DEBIAN_FRONTEND=noninteractive


RUN --mount=target=/ccws_docker_context,ro \
    cd /ccws_docker_context \
    && mkdir -p /ccws/workspace \
    && cp -r .clang-format .git .github .gitignore LICENSE Makefile README.md ccws setup.bash /ccws/ \
    && cd /ccws \
    && ((git config --remove-section 'http.https://github.com/') || true)

WORKDIR /ccws
ENV WORKSPACE_DIR=/ccws/workspace

RUN \
--mount=type=cache,target=/var/cache/apt,sharing=locked \
--mount=type=cache,target=/var/lib/apt/lists/,sharing=locked \
--mount=type=cache,target=/cache/pip,sharing=locked \
    rm /etc/apt/apt.conf.d/docker-clean \
    && apt update \
    && apt upgrade -y \
    && ${APT_INSTALL} neovim screen git ssh \
    && cd /ccws \
    && ./ccws/scripts/bootstrap.sh \
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
