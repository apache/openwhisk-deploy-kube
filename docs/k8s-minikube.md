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

# Using Minikube for OpenWhisk

## Overview

Minikube runs a single node Kubernetes cluster inside of a VM
(virtual machine) running on your host machine. Depending on your host
machine, you will have different choices for the VM.
Minikube is suitable for developing and testing of OpenWhisk.  Because
the Kubernetes cluster is run within another VM, Minikube is slightly
more resource intensive and slightly less flexible than some of the
other docker-in-docker based approaches to running Kubernetes.

## Initial Minikube Setup

New versions of Minikube and Kubernetes are released fairly
frequently.  Over time, you will probably end up needing to have
multiple versions installed on your development machine. We recommend
using the asdf package manager to make it very easy to switch between
versions and manage installation.

### Install and configure asdf

#### MacOS
```
brew install asdf
```

Edit your `~/.profile` or equivalent
```
[ -s "/usr/local/opt/asdf/asdf.sh" ] && . /usr/local/opt/asdf/asdf.sh
```

#### Other Platforms

Follow the asdf installation instructions at https://github.com/asdf-vm/asdf

### Add minikube and kubectl plugins
```
asdf plugin-add kubectl
asdf plugin-add minikube
```

### Install minikube and kubectl using asdf.

We recommend starting a combination of minikube 0.28.2 and kubectl
1.10.5 that are known to work for running OpenWhisk.  After you have
experience with OpenWhisk on Minikube, feel free to experiment with
additional versions.

```
asdf install kubectl 1.10.5
asdf global kubectl 1.10.5
asdf install minikube 0.28.2
asdf global minikube 0.28.2
```

### Configure the Minikube VM

You will want at least 4GB of memory and 2 CPUs for Minikube to run OpenWhisk.
If you have a larger machine, you may want to provision more (especially more memory).

```
minikube config set kubernetes-version v1.10.5
minikube config set cpus 2
minikube config set memory 4096
minikube config set WantUpdateNotification false
```

### Start Minikube

With minikube v0.25.2:
```
minikube start --extra-config=apiserver.Authorization.Mode=RBAC
```
with minikube versions more recent than v0.25.2:
```
minikube start
```

### Setup Docker network in promiscuous mode
Put the docker network in promiscuous mode.
```
minikube ssh -- sudo ip link set docker0 promisc on
```

**Tip**: Make sure to setup the Docker network after `minkube start` if you ran `minkube delete` as this configuration will be lost.

Your Minikube cluster should now be ready to deploy OpenWhisk.

### Changing Kubernetes versions

To use a different version of Kubernetes with Minikube, you need to delete the VM, reconfigure minikube, restart, and
redo the setup of the Docker network.
```
minikube delete
minikube config set kubernetes-version <NEW_VERSION>
minikube start [--extra-config=apiserver.Authorization.Mode=RBAC]
minikube ssh -- sudo ip link set docker0 promisc on
```

## Configuring OpenWhisk

You will be using a NodePort ingress to access OpenWhisk. Assuming
`minikube ip` returns `192.168.99.100` and port 31001 is available to
be used on your host machine, a
mycluster.yaml for a standard deployment of OpenWhisk would be:
```yaml
whisk:
  ingress:
    type: NodePort
    apiHostName: 192.168.99.100
    apiHostPort: 31001

nginx:
  httpsNodePort: 31001
```

## Limitations

Using Minikube is only appropriate for development and testing
purposes.  It is not recommended for production deployments of
OpenWhisk.

TLS termination will be handled by OpenWhisk's `nginx` service and
will use self-signed certificates.  You will need to invoke `wsk` with
the `-i` command line argument to bypass certificate checking.

You must remember to put the docker network in promiscuous mode via
```
minikube ssh -- sudo ip link set docker0 promisc on
```
every time you start minikube.
