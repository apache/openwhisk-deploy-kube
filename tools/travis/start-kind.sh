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
    v1.14) KIND_NODE_TAG=v1.14.10@sha256:6cd43ff41ae9f02bb46c8f455d5323819aec858b99534a290517ebc181b443c6 ;;
    v1.15) KIND_NODE_TAG=v1.15.11@sha256:6cc31f3533deb138792db2c7d1ffc36f7456a06f1db5556ad3b6927641016f50 ;;
    v1.16) KIND_NODE_TAG=v1.16.9@sha256:7175872357bc85847ec4b1aba46ed1d12fa054c83ac7a8a11f5c268957fd5765 ;;
    v1.17) KIND_NODE_TAG=v1.17.5@sha256:ab3f9e6ec5ad8840eeb1f76c89bb7948c77bbf76bcebe1a8b59790b8ae9a283a ;;
    v1.18) KIND_NODE_TAG=v1.18.2@sha256:7b27a6d0f2517ff88ba444025beae41491b016bc6af573ba467b70c5e8e0d85f ;;
    *) echo "Unsupported Kubernetes version $TRAVIS_KUBE_VERSION"; exit 1 ;;
esac

# Boot cluster
kind create cluster --config mycluster.yaml --name kind --image kindest/node:${KIND_NODE_TAG} --wait 10m || exit 1

echo "Kubernetes cluster is deployed and reachable"
kubectl describe nodes
