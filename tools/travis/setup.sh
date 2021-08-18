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

HELM_VERSION=v3.2.4
# When changing KIND_VERSION, you must also update the case statement of KIND_NODE_TAG in start-kind.sh
KIND_VERSION=v0.11.1
KUBECTL_VERSION=v1.18.8
WSK_CLI_VERSION=latest

# Download and install command line tools
pushd /tmp
  # kubectl
  curl -Lo ./kubectl https://storage.googleapis.com/kubernetes-release/release/$KUBECTL_VERSION/bin/linux/amd64/kubectl
  chmod +x kubectl
  sudo cp kubectl /usr/local/bin/kubectl

  # kind
  curl -Lo ./kind https://github.com/kubernetes-sigs/kind/releases/download/$KIND_VERSION/kind-linux-amd64
  chmod +x kind
  sudo cp kind /usr/local/bin/kind

  # wsk cli
  wget -q https://github.com/apache/openwhisk-cli/releases/download/$WSK_CLI_VERSION/OpenWhisk_CLI-$WSK_CLI_VERSION-linux-amd64.tgz
  tar xzf OpenWhisk_CLI-$WSK_CLI_VERSION-linux-amd64.tgz
  sudo cp wsk /usr/local/bin/wsk

  # helm3
  curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get-helm-3 > get-helm-3.sh && chmod +x get-helm-3.sh && ./get-helm-3.sh --version $HELM_VERSION
popd

# Install additional python packages for box-upload.py
pip install --user humanize requests
