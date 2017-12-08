#!/bin/bash
set -exu

dockerhub_image_prefix="$1"
dockerhub_image_name="$2"
dockerhub_image_tag="$3"
dir_to_build="$4"
dockerhub_image="${dockerhub_image_prefix}/${dockerhub_image_name}:${dockerhub_image_tag}"

docker login -u "${DOCKER_USER}" -p "${DOCKER_PASSWORD}"
docker build ${dir_to_build} --tag ${dockerhub_image}
docker push ${dockerhub_image}
