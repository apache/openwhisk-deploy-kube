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

# Intall python packages used by box-upload.py
pip install --user humanize requests

# Download and install misc packages and utilities
pushd /tmp
  # Install kubectl
  curl -Lo ./kubectl https://storage.googleapis.com/kubernetes-release/release/v1.16.1/bin/linux/amd64/kubectl
  chmod +x kubectl
  sudo cp kubectl /usr/local/bin/kubectl

  # download and install the wsk cli
  wget -q https://github.com/apache/openwhisk-cli/releases/download/latest/OpenWhisk_CLI-latest-linux-amd64.tgz
  tar xzf OpenWhisk_CLI-latest-linux-amd64.tgz
  sudo cp wsk /usr/local/bin/wsk

  # Download and install helm 2 (remove tiller init from start-kind.sh when upgrading to helm 3)
  curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get > get_helm.sh && chmod +x get_helm.sh && ./get_helm.sh --version v2.16.1
popd

