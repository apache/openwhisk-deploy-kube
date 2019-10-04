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


# Deploying OpenWhisk on kind

## Overview

You can run Kubernetes on top of Docker on Linux, MacOS, and Windows using the
[kind](https://github.com/kubernetes-sigs/kind) project.
Based on using Docker-in-Docker (DIND) virtualization and
`kubeadm`, kind can be used to create a virtual multi-node
Kubernetes cluster that is suitable for deploying
OpenWhisk for development and testing.  For detailed instructions on kind, we
refer you to that project's [github repository](https://github.com/kubernetes-sigs/kind).
Here we will only cover the basic operations needed to create and
operate a default cluster with two virtual worker nodes.

## Initial setup

Download the latest stable release of `kind` for your platform from
https://github.com/kubernetes-sigs/kind/releases. Our TravisCI testing
currently uses kind v0.5.1 on an ubuntu 18.04 host.

### Creating the Kubernetes Cluster

On Linux, make sure your userid is in the `docker` group on the host
machine.  This will enable you to run `kind` without
requiring `sudo` to gain `root` privileges.

Create a kind-cluster.yaml to configure your cluster.
```yaml
kind: Cluster
apiVersion: kind.sigs.k8s.io/v1alpha3
nodes:
- role: control-plane
- role: worker
  extraPortMappings:
    - hostPort: 31001
      containerPort: 31001
- role: worker
```
The extraPortMappings stanza enables port forwarding
from the localhost to the in-cluster network.
This is required on MacOS, but to simplify the instructions
we use the same setup for all platforms.

Now create your cluster with the command:
```shell
kind create cluster --config kind-cluster.yaml
```

Next, configure `kubectl` by executing
```shell
KUBECONFIG="$(kind get kubeconfig-path)"
```

Then label the two worker nodes so that one is reserved for the invoker
and the other will be used to run the rest of the OpenWhisk system.
```shell
kubectl label node kind-worker openwhisk-role=core
kubectl label node kind-worker2 openwhisk-role=invoker
```

### Configuring OpenWhisk

To configure OpenWhisk, you first need to define a mycluster.yaml
that specifies the "inside the cluster" ingress information and
other system configuration. First, determine the internalIP of
a worker node with the command:
```
kubectl describe node kind-worker | grep InternalIP: | awk '{print $2}'
```
A mycluster.yaml for a standard deployment of OpenWhisk would look
like the below, replacing <InternalIP> with its actual value:
```yaml
whisk:
  ingress:
    type: NodePort
    apiHostName: <INTERNAL_IP>
    apiHostPort: 31001

invoker:
  containerFactory:
    impl: "kubernetes"

nginx:
  httpsNodePort: 31001
```
Note that you must use the KubernetesContainerFactory when running
OpenWhisk on `kind` because it is configured to use `containerd`
as the underlying container engine.

External to the Kubernetes cluster, for example when using the `wsk` cli,
we will use the port forwarding configured by the `extraPortMappings`
in kind-cluster.yaml to allow the OpenWhisk apihost property
to be set to localhost:31001

## Limitations

Using kind is only appropriate for development and testing purposes.
It is not recommended for production deployments of OpenWhisk.

TLS termination will be handled by OpenWhisk's `nginx` service and
will use self-signed certificates.  You will need to invoke `wsk` with
the `-i` command line argument to bypass certificate checking.

Unlike using Kubernetes with Docker for Mac 18.06 and later, only the
virtual master/worker nodes are visible to Docker on the host system. The
individual pods running the OpenWhisk system are only visible using
`kubectl` and not directly via host Docker commands.
