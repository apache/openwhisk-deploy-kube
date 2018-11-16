#!/bin/bash
# Licensed to the Apache Software Foundation (ASF) under one or more contributor
# license agreements; and to You under the Apache License, Version 2.0.

set -exu

dockerhub_image_prefix="$1"
dockerhub_image_name="$2"
dockerhub_image_tag="$3"
dir_to_build="$4"
dockerhub_image="${dockerhub_image_prefix}/${dockerhub_image_name}:${dockerhub_image_tag}"

docker login -u "${DOCKER_USER}" -p "${DOCKER_PASSWORD}"
docker build ${dir_to_build} --tag ${dockerhub_image}
docker push ${dockerhub_image}

if [ ${dockerhub_image_tag} == "latest" ]; then
    short_commit=`git rev-parse --short HEAD`
    dockerhub_image_alias="${dockerhub_image_prefix}/${dockerhub_image_name}:${short_commit}"
    docker tag ${dockerhub_image} ${dockerhub_image_alias}
    docker push ${dockerhub_image_alias}
fi
