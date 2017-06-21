#!/usr/bin/env bash

# This script can be used to build the custom docker images required
# for deploying openwhisk on Kubernetes.

set -ex

if [ -z "$1" ]; then
cat <<- EndOfMessage
  First argument should be location of which docker repo to push all
  of the built OpenWhisk docker images. This way, Kubernetes can pull
  any images it needs to.
EndOfMessage

exit 1
fi


OPENWHISK_DIR=""
if [ -z "$2" ]; then
cat <<- EndOfMessage
  Second argument should be location of the OpenWhisk repo on the local
  file system. By default, it is assumed to be at $HOME/workspace/openwhisk.
EndOfMessage
  OPENWHISK_DIR=$HOME/workspace/openwhisk
else
  OPENWHISK_DIR="$2"
fi


SOURCE="${BASH_SOURCE[0]}"
SCRIPTDIR="$( dirname "$SOURCE" )"

# build nginx
pushd $SCRIPTDIR/nginx
 mkdir -p blackbox
 pushd blackbox
   # copy docker sdk to dockerSkeleton in scratch space
   cp $OPENWHISK_DIR/sdk/docker/buildAndPush.sh .
   cp $OPENWHISK_DIR/sdk/docker/Dockerfile .
   cp $OPENWHISK_DIR/sdk/docker/example.c .
   cp $OPENWHISK_DIR/sdk/docker/README.md .

   # rename base image in Dockerfile
   sed -i "s|FROM dockerskeleton|FROM openwhisk/dockerskeleton|g" Dockerfile

   # fix file permissions
   chmod 0755 buildAndPush.sh

   # build blackbox container artifact
   tar -czf ../blackbox-0.1.0.tar.gz .
 popd

 NGINX_IMAGE=$(docker build . | grep "Successfully built" | awk '{print $3}')
 docker tag $NGINX_IMAGE "$1"/whisk_nginx
 docker push "$1"/whisk_nginx

 # cleanup
 rm blackbox-0.1.0.tar.gz
 rm -rf blackbox
popd

BuildKubeConfigureImage () {
  pushd $SCRIPTDIR/..

   WHISK_DEPLOY_IMAGE=$(docker build --build-arg KUBE_VERSION="$2" . | grep "Successfully built" | awk '{print $3}')
   docker tag $WHISK_DEPLOY_IMAGE "$1"/whisk_config:"$2"-dev
   docker push "$1"/whisk_config:"$2"-dev

  popd
}

# build the OpenWhisk configure image
BuildKubeConfigureImage "$1" "v1.5.6"
BuildKubeConfigureImage "$1" "v1.6.2"

