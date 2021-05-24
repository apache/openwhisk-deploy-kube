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

### Configuring OpenWhisk

You will be using a NodePort ingress to access OpenWhisk. Assuming
`kubectl describe nodes | find "InternalIP"` returns 192.168.65.3 and
port 31001 is available to be used on your host machine, a
[mycluster.yaml](../deploy/docker-windows/mycluster.yaml) for a standard deployment of OpenWhisk would be:

```yaml
whisk:
  ingress:
    type: NodePort
    apiHostName: localhost
    apiHostPort: 31001
    useInternally: false

nginx:
  httpsNodePort: 31001

# A single node cluster; so disable affinity
affinity:
  enabled: false
toleration:
  enabled: false
invoker:
  options: "-Dwhisk.kubernetes.user-pod-node-affinity.enabled=false"
```

## Hints and Tips

If you notice errors or pods stuck in the pending state (`init-couchdb`
as an example), try running `kubectl get pvc --all-namespaces`. If you notice
that claims are stuck in the Pending state, you may need to follow the
workaround mentioned in this [Docker for Windows Github Issue](https://github.com/docker/for-win/issues/1758#issuecomment-376054370).

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
