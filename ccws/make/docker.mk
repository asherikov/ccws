CCWS_DOCKER_BASE_IMAGE?=ros:noetic-ros-base
CCWS_DOCKER_TAG?=$(shell cat "${CCWS_SOURCE_DIR}/.ccws/docker")
CCWS_DOCKER_FILE?="${CCWS_SOURCE_DIR}/.ccws/Dockerfile"
PLATFORM=$(shell dpkg --print-architecture)

export DOCKER_DEFAULT_PLATFORM=linux/${PLATFORM}
export BUILDKIT_PROGRESS=plain


docker_run:
	docker run -ti --rm -v ./:/ccws ${CCWS_DOCKER_TAG} env CCWS_CACHE=/ccws/cache bash

docker_build:
	docker build -f ${CCWS_DOCKER_FILE} \
		--no-cache \
		--build-arg BASE_IMAGE="${CCWS_DOCKER_BASE_IMAGE}" \
		--tag "${CCWS_DOCKER_TAG}" \
		./

docker_build_example:
	${MAKE} docker_build CCWS_DOCKER_FILE="${CCWS_DIR}/examples/Dockerfile" CCWS_DOCKER_TAG=ccws_example

docker_run_example:
	${MAKE} docker_run CCWS_DOCKER_TAG=ccws_example

docker_install:
	# https://docs.docker.com/engine/install/ubuntu/
	sudo install -m 0755 -d /etc/apt/keyrings
	wget -qO- https://download.docker.com/linux/ubuntu/gpg | sudo tee /etc/apt/keyrings/docker.asc
	sudo chmod a+r /etc/apt/keyrings/docker.asc
	echo \
    	"deb [arch=${PLATFORM} signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu ${OS_DISTRO_BUILD} stable" \
		| sudo tee /etc/apt/sources.list.d/docker.list
	sudo apt update
	sudo ${APT_INSTALL} docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
	sudo usermod -aG docker ${USER}
	sudo systemctl enable docker


# make docker_extract PLATFORM=arm64 IMAGE=ubuntu:latest
docker_extract:
	mkdir -p "${CCWS_CACHE}/${CCWS_BUILD_PROFILES_ID}/docker/"
	# https://labs.iximiuz.com/tutorials/extracting-container-image-filesystem
	docker create "${IMAGE}" \
		| xargs -I {} sh -c "docker container export '{}' -o "${CCWS_CACHE}/${CCWS_BUILD_PROFILES_ID}/docker/${IMAGE}_rootfs.tar.gz" \
		&& docker container rm '{}'"

private_docker_mountpoint:
	mkdir -p "${CCWS_SYSROOT_DIR}"
	cd "${CCWS_SYSROOT_DIR}" \
		&& (test ! -d mountpoint || ((sudo umount --recursive mountpoint || true) && mv mountpoint mountpoint_`date +%s`)) \
		&& mkdir -p mountpoint
	cd "${CCWS_SYSROOT_DIR}/mountpoint" && sudo tar -xf "${CCWS_CACHE}/${CCWS_BUILD_PROFILES_ID}/docker/${IMAGE}_rootfs.tar.gz"

# make docker_mountpoint PLATFORM=arm64 IMAGE=ubuntu:latest
docker_mountpoint: docker_extract
	${MAKE} wswraptarget TARGET=private_docker_mountpoint
