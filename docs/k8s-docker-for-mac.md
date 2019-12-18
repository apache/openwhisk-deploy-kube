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

# Deploying OpenWhisk on Kubernetes in Docker for Mac

## Overview

If you are using a Mac as your development machine, the simplest way
to get a Kubernetes cluster for local development is to use the
built-in support for running a single node Kubernetes cluster that is
available in Docker 18.06 and later.  This will let you use Helm to
deploy Apache OpenWhisk to Kubernetes on your laptop without needing
any additional virtualization software installed.

## Initial setup

### Creating the Kubernetes Cluster

Step-by-step instructions on enabling Kubernetes in Docker are
available as part of the
[Getting started](https://docs.docker.com/docker-for-mac/#Kubernetes)
documentation from Docker.

In a nutshell, open the Docker preferences window, switch to the
`Advanced` panel and make sure you have at least 4GB of Memory
allocated to Docker. Then switch to the Kubernetes panel, and check
the box to enable Kubernetes. It is recommended that you use the
`kubectl` cli that is installed by Docker in `/usr/local/bin`, so
please make sure it is appears in your path before any `kubectl` you
might also have installed on your machine.  Finally, pick the
`docker-for-desktop` config for `kubectl` by executing the command
`kubectl config use-context docker-for-desktop`.

### Configuring OpenWhisk

You will be using a NodePort ingress to access OpenWhisk. Assuming
`kubectl describe nodes | grep InternalIP` returns 192.168.65.3 and
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

Using Kubernetes in Docker for Mac is only appropriate for development
and testing purposes.  It is not recommended for production
deployments of OpenWhisk.

TLS termination will be handled by OpenWhisk's `nginx` service and
will use self-signed certificates.  You will need to invoke `wsk` with
the `-i` command line argument to bypass certificate checking.

The docker network is not exposed to the host on MacOS. However, the
exposed ports for NodePort services are forwarded from localhost.
Therefore you must use different host names to connect to OpenWhisk
from outside the cluster (with the `wsk` cli) and from inside the
cluster (in `mycluster.yaml`).  Continuing the example from above,
when setting the `--apihost` for the `wsk` cli, you would use
`localhost:31001`.  This networking difference also shows up when
listing apis via `wsk -i api list`. The listed URLs will show the
cluster-internal apihost,
e.g. `https://192.168.65.3:31001/api/<UID>/<PATH>`, to invoke the api
from outside the cluster you should use `localhost:31001` instead, e.g.
`https://localhost:31001/api/<UID>/<PATH>`.
