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

# Setting Up Minikube for OpenWhisk

First, download and install Minikube following these [instructions](https://github.com/kubernetes/minikube).

## Setup MacOS for local minikube
We recommend using the same versions we use in Travis, using asdf makes it very easy to select the version of minikube and kubectl

### Install asdf
```
brew install asdf
```
### Setup asdf in terminal
Edit your `~/.profile` or equivalent
```
[ -s "/usr/local/opt/asdf/asdf.sh" ] && . /usr/local/opt/asdf/asdf.sh
```

### Add minikune and kubectl plugins
```
asdf plugin-add kubectl
asdf plugin-add minikube
```

### Install asdf plugin minikube@0.25.2 and kubectl@1.9.0
```
asdf install kubectl 1.9.0
asdf global kubectl 1.9.0
asdf install minikube 0.25.2
asdf global minikube 0.25.2
```

## Create the minikube VM
You will want at least 4GB of memory and 2 CPUs for Minikube to run OpenWhisk.
If you have a larger machine, you may want to provision more (especially more memory).

Start Minikube with:
```
minikube start --cpus 2 --memory 4096 --kubernetes-version=v1.9.0 --extra-config=apiserver.Authorization.Mode=RBAC
```

## Setup Docker network in promiscuous mode
Put the docker network in promiscuous mode.
```
minikube ssh -- sudo ip link set docker0 promisc on
```

Your Minikube cluster should now be ready to deploy OpenWhisk.

# Troubleshooting

For some combinations of Minikube and Kubernetes versions, you may need to workaround a [Minikube DNS issue](https://github.com/kubernetes/minikube/issues/2240#issuecomment-348319371). A common symptom of this issue is that the OpenWhisk couchdb pod will fail to start with the error that it is unable to resolve `github.com` when cloning the openwhisk git repo. A work around is to delete the minikube cluster, issue the command `minikube config set bootstrapper kubeadm` and then redo the `minikube start` command above.
