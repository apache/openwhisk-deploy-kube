#!/bin/bash
#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

set -x

SCRIPTDIR=$(cd $(dirname "$0") && pwd)

TRAVIS_KUBE_VERSION=${TRAVIS_KUBE_VERSION:="v1.20"}

# Map from Kubernetes major versions to the kind node image tag
case $TRAVIS_KUBE_VERSION in
    v1.19) KIND_NODE_TAG=v1.19.11@sha256:07db187ae84b4b7de440a73886f008cf903fcf5764ba8106a9fd5243d6f32729 ;;
    v1.20) KIND_NODE_TAG=v1.20.7@sha256:cbeaf907fc78ac97ce7b625e4bf0de16e3ea725daf6b04f930bd14c67c671ff9  ;;
    v1.21) KIND_NODE_TAG=v1.21.1@sha256:69860bda5563ac81e3c0057d654b5253219618a22ec3a346306239bba8cfa1a6  ;;
    *) echo "Unsupported Kubernetes version $TRAVIS_KUBE_VERSION"; exit 1 ;;
esac

# Boot cluster
kind create cluster --config "$SCRIPTDIR/kind-cluster.yaml" --name kind --image kindest/node:${KIND_NODE_TAG} --wait 10m || exit 1

echo "Kubernetes cluster is deployed and reachable"
kubectl describe nodes
