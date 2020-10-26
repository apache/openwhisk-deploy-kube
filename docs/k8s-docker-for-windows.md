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

# Deploying OpenWhisk on Kubernetes in Docker for Windows

## Overview

If you are using Windows as your development machine, the simplest way
to get a Kubernetes cluster for local development is to use the
built-in support for running a single node Kubernetes cluster that is
available in Docker 18.06 and later. This will let you use Helm to
deploy Apache OpenWhisk to Kubernetes on your computer without needing
any additional virtualization software installed.

## Quick-start

### Chocolatey

You can use the Chocolatey package manager to quickly set up your Docker
cluster on Windows.

- [Install Chocolatey](https://chocolatey.org/install)
- Install Docker Desktop: `choco install docker-desktop`
- Install helm: `choco install kubernetes-helm`

## Initial setup

### Creating the Kubernetes Cluster

Step-by-step instructions on enabling Kubernetes in Docker are
available as part of the
[Getting started](https://docs.docker.com/docker-for-windows/#kubernetes)
documentation from Docker.

In a nutshell, open the Docker preferences window, switch to the
`Advanced` panel and make sure you have **at least 4GB of Memory
allocated to Docker**. Then switch to the Kubernetes panel, and check
the box to enable Kubernetes.

### Using Git to Clone this Repository

`git clone https://github.com/apache/openwhisk-deploy-kube.git`

### Configuring OpenWhisk

You will be using a NodePort ingress to access OpenWhisk. Assuming
`kubectl describe nodes | find "InternalIP"` returns 192.168.65.3 and
port 31001 is available to be used on your host machine, a
mycluster.yaml for a standard deployment of OpenWhisk would be:

```yaml
whisk:
  ingress:
    type: NodePort
    apiHostName: 192.168.65.3
    apiHostPort: 31001

nginx:
  httpsNodePort: 31001
```

### Using helm to install OpenWhisk

Installation expects `openwhisk` namespace to be created. To create, run

`kubectl create namespace openwhisk`

Indicate the Kubernetes worker nodes that should be used to execute user
containers by OpenWhisk's invokers. For a single node development cluster,
simply run:

`kubectl label nodes --all openwhisk-role=invoker`

Make sure you created your
`mycluster.yaml` file as described above, and run:

```cmd
cd openwhisk-deploy-kube
helm install owdev ./helm/openwhisk -n openwhisk -f mycluster.yaml
```

You can use the command `helm status owdev -n openwhisk` to get a summary of the various
Kubernetes artifacts that make up your OpenWhisk deployment. Once the
`install-packages` Pod is in the Completed state, your OpenWhisk deployment
is ready to be used.

Tip: If you notice errors or pods stuck in the pending state (`init-couchdb`
as an example), try running `kubectl get pvc --all-namespaces`. If you notice
that claims are stuck in the Pending state, you may need to follow the
workaround mentioned in this [Docker for Windows Github Issue](https://github.com/docker/for-win/issues/1758#issuecomment-376054370).

You are now ready to set up the wsk cli. Further instructions can be
[found here](https://github.com/apache/openwhisk-deploy-kube#https://github.com/apache/openwhisk-deploy-kube#configure-the-wsk-cli).
Follow the Docker for Windows instructions.

## Hints and Tips

One nice feature of using Kubernetes in Docker, is that the
containers being run in Kubernetes are also directly
visible/accessible via the usual Docker commands. Furthermore, it is
straightforward to deploy local images by adding a stanza to your
mycluster.yaml. For example, to use a locally built controller image,
just add the stanza below to your `mycluster.yaml` to override the default
behavior of pulling a stable `openwhisk/controller` image from Docker Hub.

```yaml
controller:
  imageName: "whisk/controller"
  imageTag: "latest"
```

## Limitations

Using Kubernetes in Docker for Windows is only appropriate for development
and testing purposes. It is not recommended for production
deployments of OpenWhisk.

TLS termination will be handled by OpenWhisk's `nginx` service and
will use self-signed certificates. You will need to invoke `wsk` with
the `-i` command line argument to bypass certificate checking.

The docker network is not exposed to the host on Windows. However, the
exposed ports for NodePort services are forwarded from localhost.
Therefore you must use different host names to connect to OpenWhisk
from outside the cluster (with the `wsk` cli) and from inside the
cluster (in `mycluster.yaml`). Continuing the example from above,
when setting the `--apihost` for the `wsk` cli, you would use
`localhost:31001`.
