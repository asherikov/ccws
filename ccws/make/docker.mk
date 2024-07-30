CCWS_DOCKER_BASE_IMAGE?=ros:noetic-ros-base
CCWS_DOCKER_TAG?=$(shell cat "${WORKSPACE_SRC}/.ccws/docker")
CCWS_DOCKER_FILE?="${WORKSPACE_SRC}/.ccws/Dockerfile"

export BUILDKIT_PROGRESS=plain


docker_run:
	docker run -ti --rm -v ./:/ccws ${CCWS_DOCKER_TAG} env CCWS_CACHE=/ccws/cache bash

docker_build:
	docker build -f ${CCWS_DOCKER_FILE} \
		--build-arg BASE_IMAGE="${CCWS_DOCKER_BASE_IMAGE}" \
		--tag "${CCWS_DOCKER_TAG}" \
		./

docker_build_example:
	${MAKE} docker_build CCWS_DOCKER_FILE="${CCWS_DIR}/examples/Dockerfile" CCWS_DOCKER_TAG=ccws_example

docker_run_example:
	${MAKE} docker_run CCWS_DOCKER_TAG=ccws_example
