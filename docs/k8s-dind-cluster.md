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


# Using kubeadm-dind-cluster for OpenWhisk

## Overview

On Linux, you can run Kubernetes on top of Docker using the
[kubeadm-dind-cluster](https://github.com/kubernetes-sigs/kubeadm-dind-cluster)
project.  Based on using Docker-in-Docker (DIND) virtualization and
`kubeadm`, kubeadm-dind-cluster can be used to create a
multi-node Kubernetes cluster that is suitable for deploying
OpenWhisk for development and testing.  For detailed instructions on kubeadm-dind-cluster, we
refer you to that project's [github repository](https://github.com/kubernetes-sigs/kubeadm-dind-cluster).
Here we will only cover the basic operations needed to create and
operate a default cluster with two virtual worker nodes running on a
single host machine.

## Initial setup

There are "fixed" scripts
[available](https://github.com/kubernetes-sigs/kubeadm-dind-cluster/tree/master/fixed)
for each major release of Kubernetes.
Our TravisCI testing uses kubeadm-dind-cluster.sh on an ubuntu 16.04
host.  The `fixed` `dind-cluster` scripts for Kubernetes version 1.10,
1.11, and 1.12 are known to work for deploying OpenWhisk.

### Creating the Kubernetes Cluster

First, make sure your userid is in the `docker` group on the host
machine.  This will enable you to run `dind-cluster.sh` script without
requiring `sudo` to gain `root` privileges.

To initially create your cluster, do the following:
```shell
# Get the script for the Kubernetes version you want
wget https://cdn.rawgit.com/kubernetes-sigs/kubeadm-dind-cluster/master/fixed/dind-cluster-v1.10.sh

# Make it executable
chmod +x dind-cluster-v1.10.sh

# Start the cluster. Please note you *must* set `USE_HAIRPIN` to `true`
USE_HAIRPIN=true ./dind-cluster-v1.10.sh up

# add the directory containing kubectl to your PATH
export PATH="$HOME/.kubeadm-dind-cluster:$PATH"
```

The default configuration of `dind-cluster.sh` will create a cluster
with three nodes: 1 master node and two worker nodes. We recommend
labeling the two worker nodes for OpenWhisk so that you have 1 invoker
node for running user actions and 1 core node for running the rest of
the OpenWhisk system.
```shell
kubectl label node kube-node-1 openwhisk-role=core
kubectl label node kube-node-2 openwhisk-role=invoker
```

### Configuring OpenWhisk


You will be using a NodePort ingress to access OpenWhisk. Assuming
`kubectl describe node kube-node-1 | grep InternalIP` returns 10.192.0.3
and port 31001 is available to be used on your host machine, a
mycluster.yaml for a standard deployment of OpenWhisk would be:
```yaml
whisk:
  ingress:
    type: NodePort
    apiHostName: 10.192.0.3
    apiHostPort: 31001

nginx:
  httpsNodePort: 31001

invoker:
  containerFactory:
    dind: true

k8s:
  persistence:
    enabled: false
```

Note the stanza setting `invoker.containerFactory.dind` to true. This
is needed because the logs for docker containers running on the
virtual worker nodes are in a non-standard location, requiring special
configuration of OpenWhisk's invoker pods. Failure to set this
variable when running on kubeadm-dind-cluster will result in an
OpenWhisk deployment that cannot execute user actions.

For ease of deployment, you should also disable persistent volumes
because kubeadm-dind-cluster does not configure a default
StorageClass.

## Limitations

Using kubeadm-dind-cluster is only appropriate for development and
testing purposes.  It is not recommended for production deployments of
OpenWhisk.

Without enabling persistence, it is not possible to restart the
Kubernetes cluster without also re-installing Helm and OpenWhisk.

TLS termination will be handled by OpenWhisk's `nginx` service and
will use self-signed certificates.  You will need to invoke `wsk` with
the `-i` command line argument to bypass certificate checking.

Unlike using Kubernetes with Docker for Mac 18.06 and later, only the
virtual master/worker nodes are visible to Docker on the host system. The
individual pods running the OpenWhisk system are only visible using
`kubectl` and not directly via host Docker commands.
