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

# Install kubectl
curl -Lo ./kubectl https://storage.googleapis.com/kubernetes-release/release/v1.16.1/bin/linux/amd64/kubectl
chmod +x kubectl
sudo cp kubectl /usr/local/bin/kubectl

# Install kind
curl -Lo ./kind https://github.com/kubernetes-sigs/kind/releases/download/v0.5.1/kind-linux-amd64
chmod +x kind
sudo cp kind /usr/local/bin/kind

# Boot kind
cat > mycluster.yaml <<EOF
kind: Cluster
apiVersion: kind.sigs.k8s.io/v1alpha3
nodes:
- role: control-plane
- role: worker
- role: worker
EOF

kind create cluster --config mycluster.yaml --name kind --image kindest/node:${TRAVIS_KUBE_VERSION} --wait 300s

export KUBECONFIG="$(kind get kubeconfig-path)"

echo "Kubernetes cluster is deployed and reachable"
kubectl describe nodes

# Download and install misc packages and utilities
pushd /tmp
  # download and install the wsk cli
  wget -q https://github.com/apache/openwhisk-cli/releases/download/latest/OpenWhisk_CLI-latest-linux-amd64.tgz
  tar xzf OpenWhisk_CLI-latest-linux-amd64.tgz
  sudo cp wsk /usr/local/bin/wsk

  # Download and install helm
  curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get > get_helm.sh && chmod +x get_helm.sh && ./get_helm.sh
popd

# Pods running in kube-system namespace should have cluster-admin role
kubectl create clusterrolebinding add-on-cluster-admin --clusterrole=cluster-admin --serviceaccount=kube-system:default

# Install tiller into the cluster
/usr/local/bin/helm init --service-account default

# Wait for tiller to be ready
TIMEOUT=0
TIMEOUT_COUNT=60
until [ $TIMEOUT -eq $TIMEOUT_COUNT ]; do
  TILLER_STATUS=$(kubectl -n kube-system get pods -o wide | grep tiller-deploy | awk '{print $3}')
  TILLER_READY_COUNT=$(kubectl -n kube-system get pods -o wide | grep tiller-deploy | awk '{print $2}')
  if [[ "$TILLER_STATUS" == "Running" ]] && [[ "$TILLER_READY_COUNT" == "1/1" ]]; then
    break
  fi
  echo "Waiting for tiller to be ready"
  kubectl -n kube-system get pods -o wide
  let TIMEOUT=TIMEOUT+1
  sleep 5
done

if [ $TIMEOUT -eq $TIMEOUT_COUNT ]; then
  echo "Failed to install tiller"

  # Dump diagnostic info to see why tiller failed
  kubectl -n kube-system describe pods
  exit 1
fi
