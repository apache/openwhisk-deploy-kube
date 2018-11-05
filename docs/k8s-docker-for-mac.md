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


If you are using a Mac as your development machine, the simplest way
to get a Kubernetes cluster for local development is to use the
built-in support for running a single node Kubernetes cluster that is
available in Docker 18.06 and later.  This will let you use Helm to
deploy Apache OpenWhisk to Kubernetes on your laptop without needing
to install Minikube or otherwise run inside a virtual machine.

Step-by-step instructions on enabling Kubernetes in Docker are
available as part of the
[Getting started](https://docs.docker.com/docker-for-mac/#kubernetes)
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

One nice feature of using Kubernetes in Docker, is that the
containers being run in Kubernetes are also directly
visible/accessible via the usual Docker commands. Furthermore, it is
straightforward to deploy local images by adding a stanza to your
mycluster.yaml. For example, to use a locally built controller image,
just add the stanza below to your `mycluster.yaml` to override the default
behavior of pulling `openwhisk/controller:latest` from Docker Hub.
```yaml
controller:
  image: "whisk/controller"
  imagePullPolicy: "IfNotPresent"
```
