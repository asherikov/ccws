ARG BASE_IMAGE=ubuntu:noble
FROM ${BASE_IMAGE}

# these would override CCWS commands
ENV APT_INSTALL="env DEBIAN_FRONTEND=noninteractive apt --yes --no-install-recommends install"
ENV PIPX_INSTALL="python3 -m pipx install"
ENV CCWS_CACHE=/cache/ccws

ENV PIP_CACHE_DIR=${CCWS_CACHE}/pip
ENV PYTHONDONTWRITEBYTECODE=1
ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/ccws/ccws/tools/bin:${PATH}"
ENV npm_config_cache=/cache/npm

# 1. docker-clean is removed since we mount cache volumes for storing apt data
# 2. caches are mounted, keep downloaded packages
# 3. make uid 1000 (ubuntu) a sudoer and set dummy password
# 4. Remove EXTERNALLY-MANAGED to work around `externally-managed-environment` pip
#    error in Ubuntu >=24
#    https://askubuntu.com/questions/1465218/pip-error-on-ubuntu-externally-managed-environment-%C3%97-this-environment-is-extern
RUN \
--mount=type=cache,target=/var/cache/apt,sharing=locked \
--mount=type=cache,target=/var/lib/apt/lists/,sharing=locked \
--mount=type=cache,target=/cache,sharing=locked \
    rm /etc/apt/apt.conf.d/docker-clean \
    && echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/01-ccws-qwen-keep-debs \
    && apt update \
    && ${APT_INSTALL} neovim git ssh python3 tmux sudo \
    && (usermod -l ccws `id -nu 1000` --home /home/ccws 2> /dev/null || useradd -u 1000 ccws) \
    && (mv /home/ubuntu /home/ccws 2> /dev/null || mkdir -p /home/ccws/) \
    && usermod -aG sudo ccws \
    && (echo "ccws:ccws" | chpasswd) \
    && echo "ccws ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ccws \
    && (find /usr/lib/ -name EXTERNALLY-MANAGED | xargs --no-run-if-empty rm) \
    && git config --system --add safe.directory '*'

RUN \
--mount=type=cache,target=/var/cache/apt,sharing=locked \
--mount=type=cache,target=/var/lib/apt/lists/,sharing=locked \
--mount=type=cache,target=/cache,sharing=locked \
--mount=target=/ccws_docker_context,ro \
    cd /ccws_docker_context \
    && ./ccws/tools/bin/bootstrap.sh

RUN \
--mount=type=cache,target=/var/cache/apt,sharing=locked \
--mount=type=cache,target=/var/lib/apt/lists/,sharing=locked \
--mount=type=cache,target=/cache,sharing=locked \
--mount=target=/ccws_docker_context,ro \
    cd /ccws_docker_context \
    && mkdir -p /ccws/workspace \
    && cp -r .clang-format .git .github .gitignore LICENSE Makefile README.md ccws setup.bash /ccws/ \
    && cp /ccws/ccws/examples/tmux.conf /home/ccws/.tmux.conf \
    && ln -s /home/ccws/.tmux.conf /root/.tmux.conf \
    && chown -R ccws /ccws /home/ccws \
    && ssh-keyscan github.com >> /etc/ssh/ssh_known_hosts \
    && ssh-keyscan gitlab.com >> /etc/ssh/ssh_known_hosts

WORKDIR /ccws

RUN \
--mount=type=cache,target=/var/cache/apt,sharing=locked \
--mount=type=cache,target=/var/lib/apt/lists/,sharing=locked \
--mount=type=cache,target=/cache,sharing=locked \
    make install_all_profiles

ENV WORKSPACE_DIR=/ccws/workspace
