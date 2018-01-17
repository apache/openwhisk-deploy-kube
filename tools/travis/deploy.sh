#!/bin/bash

set -x

SCRIPTDIR=$(cd $(dirname "$0") && pwd)
ROOTDIR="$SCRIPTDIR/../../"

cd $ROOTDIR

echo "Publishing kube-couchdb image"
./tools/travis/publish.sh openwhisk kube-couchdb latest docker/couchdb

echo "Publishing kube-docker-pull image"
./tools/travis/publish.sh openwhisk kube-docker-pull latest docker/docker-pull

echo "Publishing kube-openwhisk-catalog image"
./tools/travis/publish.sh openwhisk kube-openwhisk-catalog latest docker/openwhisk-catalog

echo "Publishing kube-routemgmt image"
./tools/travis/publish.sh openwhisk kube-routemgmt latest docker/routemgmt

echo "Publishing kube-kafkapkginstaller image"
./tools/travis/publish.sh openwhisk kube-kafkapkginstaller latest docker/kafapkg-installer
