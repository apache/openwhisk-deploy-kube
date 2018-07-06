#!/bin/bash
# Licensed to the Apache Software Foundation (ASF) under one or more contributor
# license agreements; and to You under the Apache License, Version 2.0.

set -x

SCRIPTDIR=$(cd $(dirname "$0") && pwd)
ROOTDIR="$SCRIPTDIR/../../"

cd $ROOTDIR

echo "Publishing kube-whisk-script-runner image"
./tools/travis/publish.sh openwhisk kube-whisk-script-runner latest docker/whisk-script-runner

echo "Publishing kube-whisk-ansible-runner image"
./tools/travis/publish.sh openwhisk kube-whisk-ansible-runner latest docker/whisk-ansible-runner

echo "Publishing kube-couchdb image"
./tools/travis/publish.sh openwhisk kube-couchdb latest docker/couchdb

echo "Publishing kube-invoker-agent image"
./tools/travis/publish.sh openwhisk kube-invoker-agent latest docker/invoker-agent
