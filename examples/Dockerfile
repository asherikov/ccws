ARG BASE_IMAGE=X
FROM ${BASE_IMAGE}

ARG APT_INSTALL=X
ARG PIP_INSTALL=X

ENV PIP_CACHE_DIR=/cache/pip
ENV DEBIAN_FRONTEND noninteractive

RUN --mount=target=/ccws,rw \
--mount=type=cache,target=/var/cache/apt,sharing=locked \
--mount=type=cache,target=/var/lib/apt/lists/ \
--mount=type=cache,target=/cache/pip \
    rm /etc/apt/apt.conf.d/docker-clean \
    && apt update \
    && apt upgrade -y \
    && ${APT_INSTALL} neovim screen git ssh \
    && cd /ccws \
    && ./scripts/bootstrap.sh \
    && make bp_install_build BUILD_PROFILE=reldebug \
    && mv scripts/wshandler/yq /usr/bin/

WORKDIR /ccws
