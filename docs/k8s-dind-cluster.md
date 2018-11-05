<!--
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
-->


# Using kubeadm-dind-cluster

On Linux, you can get a similar experience to using Kubernetes in
Docker for Mac via the
[kubeadm-dind-cluster](https://github.com/kubernetes-sigs/kubeadm-dind-cluster)
project.  In a nutshell, you can get started by doing
```shell
# Get the script for the Kubernetes version you want
wget https://cdn.rawgit.com/kubernetes-sigs/kubeadm-dind-cluster/master/fixed/dind-cluster-v1.10.sh
chmod +x dind-cluster-v1.10.sh

# start the cluster. Please note you *must* set `USE_HAIRPIN` to `true`
USE_HAIRPIN=true ./dind-cluster-v1.10.sh up

# add kubectl directory to your PATH
export PATH="$HOME/.kubeadm-dind-cluster:$PATH"
```

Our TravisCI testing uses kubeadm-dind-cluster.sh on an ubuntu 16.04
host.  The `fixed` `dind-cluster` scripts for Kubernetes version 1.10
and 1.11 are known to work for deploying OpenWhisk.

Because the container logs for docker containers running on the
virtual worker nodes are in a non-standard location, you must
configure the invoker to look for user action logs in a different
path. You do that by adding the following required stanza to your
mycluster.yaml.
```yaml
invoker:
  containerFactory:
    dind: true
```
