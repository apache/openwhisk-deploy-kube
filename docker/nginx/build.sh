#!/usr/bin/env bash

# This script can be used to build Nginx
# used by OpenWhisk on Kubernetes.

set -ex

if [ -z "$1" ]; then
cat <<- EndOfMessage
  First argument should be location of which docker repo to push all
  of the built OpenWhisk docker images. This way, Kubernetes can pull
  any images it needs to.
EndOfMessage

exit 1
fi

git clone https://github.com/apache/incubator-openwhisk /tmp/openwhisk

# build nginx
mkdir -p blackbox
pushd blackbox
  # copy docker sdk to dockerSkeleton in scratch space
  cp /tmp/openwhisk/sdk/docker/buildAndPush.sh .
  cp /tmp/openwhisk/sdk/docker/Dockerfile .
  cp /tmp/openwhisk/sdk/docker/example.c .
  cp /tmp/openwhisk/sdk/docker/README.md .

  # rename base image in Dockerfile
  sed -i "s|FROM dockerskeleton|FROM openwhisk/dockerskeleton|g" Dockerfile

  # fix file permissions
  chmod 0755 buildAndPush.sh

  # build blackbox container artifact
  tar -czf ../blackbox-0.1.0.tar.gz .
popd

NGINX_IMAGE=$(docker build . --no-cache | grep "Successfully built" | awk '{print $3}')
docker tag $NGINX_IMAGE "$1"/whisk_nginx
docker push "$1"/whisk_nginx

# cleanup
rm blackbox-0.1.0.tar.gz
rm -rf blackbox
