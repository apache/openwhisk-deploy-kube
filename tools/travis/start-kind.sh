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

# Create cluster config
cat > mycluster.yaml <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
- role: worker
- role: worker
EOF

# Map from Kubernetes major versions to the kind node image tag
case $TRAVIS_KUBE_VERSION in
    v1.14) KIND_NODE_TAG=v1.14.10@sha256:ce4355398a704fca68006f8a29f37aafb49f8fc2f64ede3ccd0d9198da910146 ;;
    v1.15) KIND_NODE_TAG=v1.15.12@sha256:d9b939055c1e852fe3d86955ee24976cab46cba518abcb8b13ba70917e6547a6 ;;
    v1.16) KIND_NODE_TAG=v1.16.15@sha256:a89c771f7de234e6547d43695c7ab047809ffc71a0c3b65aa54eda051c45ed20 ;;
    v1.17) KIND_NODE_TAG=v1.17.11@sha256:5240a7a2c34bf241afb54ac05669f8a46661912eab05705d660971eeb12f6555 ;;
    v1.18) KIND_NODE_TAG=v1.18.8@sha256:f4bcc97a0ad6e7abaf3f643d890add7efe6ee4ab90baeb374b4f41a4c95567eb  ;;
    v1.19) KIND_NODE_TAG=v1.19.1@sha256:98cf5288864662e37115e362b23e4369c8c4a408f99cbc06e58ac30ddc721600  ;;
    *) echo "Unsupported Kubernetes version $TRAVIS_KUBE_VERSION"; exit 1 ;;
esac

# Boot cluster
kind create cluster --config mycluster.yaml --name kind --image kindest/node:${KIND_NODE_TAG} --wait 10m || exit 1

echo "Kubernetes cluster is deployed and reachable"
kubectl describe nodes
