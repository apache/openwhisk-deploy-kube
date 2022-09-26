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
currently uses kind v0.11.1 on an ubuntu 18.04 host.

### Creating the Kubernetes Cluster

On Linux, make sure your userid is in the `docker` group on the host
machine.  This will enable you to run `kind` without
requiring `sudo` to gain `root` privileges.

We've provided a [script](../deploy/kind/start-kind.sh)
that you can use to bring up a kind cluster in a
reasonable configuration for OpenWhisk. The script
assumes that port 31001 is available on your machine
and can be used by openwhisk.  To use a different port,
edit `deploy/kind/kind-cluster.yaml`.
```
./deploy/kind/start-kind.sh
```

### Configuring OpenWhisk

Assuming you used the default port 31001 when starting kind, a
[mycluster.yaml](../deploy/kind/mycluster.yaml]
for a standard deployment of OpenWhisk would be:

```yaml
whisk:
  ingress:
    type: NodePort
    apiHostName: localhost
    apiHostPort: 31001
    useInternally: false

nginx:
  httpsNodePort: 31001

# disable affinity
affinity:
  enabled: false
toleration:
  enabled: false
invoker:
  options: "-Dwhisk.kubernetes.user-pod-node-affinity.enabled=false"
  # must use KCF as kind uses containerd as its container runtime
  containerFactory:
    impl: "kubernetes"
```
Note that you must use the KubernetesContainerFactory when running
OpenWhisk on `kind` because it is configured to use `containerd`
as the underlying container engine.

External to the Kubernetes cluster, for example when using the `wsk` cli,
we will use the port forwarding configured by the `extraPortMappings`
in [kind-cluster.yaml](../deploy/kind/kind-cluster.yaml) to allow the
OpenWhisk apihost property to be set to localhost:31001

## Hints and Tips

If you are working on the core OpenWhisk system and want
to use a locally built controller, invoker, or scheduler image
to test your changes, you need to push the image to the docker image
repository inside the `kind` cluster.

For example, suppose I had a local change to the controller
I wanted to test.  To do this, I would build the image normally
(`gradlew distDocker` in `openwhisk`). Then, execute the `kind`
command
```shell
kind load docker-image whisk/controller
```
Then add a stanza to your `mycluster.yaml` to override the default
behavior of pulling a stable `openwhisk/controller` image from Docker Hub.
```yaml
controller:
  imageName: "whisk/controller"
  imageTag: "latest"
```

Then deploy OpenWhisk normally using `helm install`. The deployed
system will use the locally built `whisk/controller` image.

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
