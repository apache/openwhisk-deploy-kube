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

# OpenWhisk Deployment on Kubernetes

[![License](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](http://www.apache.org/licenses/LICENSE-2.0)
[![Build Status](https://travis-ci.org/apache/incubator-openwhisk-deploy-kube.svg?branch=master)](https://travis-ci.org/apache/incubator-openwhisk-deploy-kube)
[![Join Slack](https://img.shields.io/badge/join-slack-9B69A0.svg)](http://slack.openwhisk.org/)

This repository can be used to deploy OpenWhisk to a Kubernetes cluster.

# Table of Contents

* [Setting up Kubernetes and Helm](#setting-up-kubernetes-and-helm)
* [Deploying OpenWhisk](#deploying-openwhisk)
* [Deploying OpenWhisk Providers](#deploying-openwhisk-providers)
* [Development and Testing](#development-and-testing)
* [Cleanup](#cleanup)
* [Issues](#issues)

# Setting up Kubernetes and Helm

## Kubernetes

### Requirements

Several requirements must be met for OpenWhisk to deploy on Kubernetes.
* [Kubernetes](https://github.com/kubernetes/kubernetes) version 1.9+. However, version 1.9.4 will not work for OpenWhisk due to a bug with volume mount subpaths (see[[kubernetes-61076](https://github.com/kubernetes/kubernetes/issues/61076)]). This bug will surface as a failure when deploying the nginx container.
* The ability to create Ingresses to make a Kubernetes service available outside of the cluster so you can actually use OpenWhisk.
* If you enable persistence (see [docs/configurationChoices.md](./docs/configurationChoices.md)), either your cluster is configured to support [Dynamic Volume Provision](https://kubernetes.io/docs/concepts/storage/dynamic-provisioning/) or you must manually create any necessary PersistentVolumes when deploying the Helm chart.
* Endpoints of Kubernetes services must be able to loopback to themselves (the kubelet's `hairpin-mode` must not be `none`).

### Using Kubernetes in Docker for Mac

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

NOTE: Docker for Windows 18.06 and later has similar built-in support
for Kubernetes. We would be interested in any experience using it to
run Apache OpenWhisk on the Windows platform.

### Using kubeadm-dind-cluster
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

### Using Minikube

If you are on Linux and do not want to use kubeadm-dind-cluster, then
an alternative for local development and testing, is using Minikube
with the docker network in promiscuous mode.  However not all
combinations of Minikube and Kubernetes versions will work for running
OpenWhisk. Some known good combinations are:

| Kubernetes Version | Minikube Version |
--- | --- |
1.9.0 | 0.25.2 |
1.10.5 | 0.28.2 |

For details on setting up Minikube, see these [instructions](docs/minikube.md).

### Using a Kubernetes cluster from a cloud provider

You can also provision a Kubernetes cluster from a cloud provider, subject to the cluster meeting the requirements above.

## Helm

[Helm](https://github.com/kubernetes/helm) is a tool to simplify the
deployment and management of applications on Kubernetes clusters. Helm
consists of the `helm` command line tool that you install on your
development machine and the `tiller` runtime that you install on your
Kubernetes cluster.

For detailed instructions on installing Helm, see these [instructions](docs/helm.md).

In short if you already have the `helm` cli installed on your development machine,
you will need to execute these two commands and wait a few seconds for the
`tiller-deploy` pod to be in the `Running` state.
```shell
helm init
kubectl create clusterrolebinding tiller-cluster-admin --clusterrole=cluster-admin --serviceaccount=kube-system:default
```

# Deploying OpenWhisk

## Overview

You will use Helm to deploy OpenWhisk to your Kubernetes cluster.
There are four deployment steps that are described in more
detail below in the rest of this section.
1. [Initial cluster setup](#initial-setup). You will create a
Kubernetes namespace into which to deploy OpenWhisk and label the
Kubernetes worker nodes to be used to execute user actions.
2. [Customize the deployment](#customize-the-deployment). You will
create a `mycluster.yaml` that specifies key facts about your
Kubernetes cluster and the OpenWhisk configuration you wish to
deploy.
3. [Deploy OpenWhisk with Helm](#deploy-with-helm). You will use Helm and
`mycluster.yaml` to deploy OpenWhisk to your Kubernetes cluster.
4. [Configure the `wsk` CLI](#configure-the-wsk-cli). You need to
tell the `wsk` CLI how to connect to your OpenWhisk deployment.

## Initial setup

1. Resources in Kubernetes are organized into namespaces. You can use
any name for the namespace you want, but we suggest using
`openwhisk`. Create one by issuing the command:
```shell
kubectl create namespace openwhisk
```

2. Identify the Kubernetes worker nodes that should be used to execute
user containers.  Do this by labeling each node with
`openwhisk-role=invoker`.  For a single node cluster, simply do
```shell
kubectl label nodes --all openwhisk-role=invoker
```
If you have a multi-node cluster, for each node <INVOKER_NODE_NAME>
you want to be an invoker, execute
```shell
$ kubectl label nodes <INVOKER_NODE_NAME> openwhisk-role=invoker
```

## Customize the Deployment

You will need to create a mycluster.yaml file that records how the
OpenWhisk deployment on your cluster will be accessed by clients.  See
the [ingress discussion](./docs/ingress.md) for details. Below is a sample
file appropriate for a Minikube cluster where `minikube ip` returns
`192.168.99.100` and port 31001 is available to be used.  If you are
using Docker for Mac, you can use the same configuration but use the
command `kubectl describe nodes | grep InternalIP` to determine the
value for `apiHostName`.  If you are using kubeadm-dind-cluster, use
the command `kubectl describe node kube-node-2 | grep InternalIP` to
determine the value for `apiHostName`.

```yaml
whisk:
  ingress:
    type: NodePort
    apiHostName: 192.168.99.100
    apiHostPort: 31001

nginx:
  httpsNodePort: 31001
```

Beyond specifying the ingress, the `mycluster.yaml` file is also used
to customize your OpenWhisk deployment by enabling optional features
and controlling the replication factor of the various microservices
that make up the OpenWhisk implementation. See the [configuration
choices documentation](./docs/configurationChoices.md) for a
discussion of the primary options.

## Deploy With Helm

Deployment can be done by using the following single command:
```shell
helm install ./helm/openwhisk --namespace=openwhisk --name=owdev -f mycluster.yaml
```
For simplicity, in this README, we have used `owdev` as the release name.
You can use a different name, or not specify a name at all and let
Helm auto-generate one for you.

You can use the command `helm status owdev` to get a summary
of the various Kubernetes artifacts that make up your OpenWhisk
deployment. Once all the pods shown by the status command are in
either the `Running` or `Completed` state, your OpenWhisk deployment
is ready to be used.

## Configure the wsk CLI

Configure the OpenWhisk CLI, wsk, by setting the auth and apihost
properties (if you don't already have the wsk cli, follow the
instructions [here](https://github.com/apache/incubator-openwhisk-cli)
to get it). Replace `whisk.ingress.apiHostName` and `whisk.ingress.apiHostPort`
with the actual values from your mycluster.yaml.
```shell
wsk property set --apihost whisk.ingress.apiHostName:whisk.ingress.apiHostPort
wsk property set --auth 23bc46b1-71f6-4ed5-8c54-816aa4f8c502:123zO3xZCLrMN6v2BKK1dXYFpXlPkccOFqm12CdAsMgRU4VrNZ9lyGVCGuMDGIwP
```
### Configuring the CLI for Kubernetes on Docker for Mac

The `docker0` network interface does not exist in the Docker for Mac
host environment. Instead, exposed NodePorts are forwarded from localhost
to the appropriate containers.  This means that you will use `localhost`
instead of `whisk.ingress.apiHostName` as your apihost when configuring
the `wsk` cli.

```shell
wsk property set --apihost localhost:whisk.ingress.apiHostPort
wsk property set --auth 23bc46b1-71f6-4ed5-8c54-816aa4f8c502:123zO3xZCLrMN6v2BKK1dXYFpXlPkccOFqm12CdAsMgRU4VrNZ9lyGVCGuMDGIwP
```

## Verify your OpenWhisk Deployment

Your OpenWhisk installation should now be usable.  You can test it by following
[these instructions](https://github.com/apache/incubator-openwhisk/blob/master/docs/actions.md)
to define and invoke a sample OpenWhisk action in your favorite programming language.

Note: if you installed self-signed certificates, which is the default
for the OpenWhisk Helm chart, you will need to use `wsk -i` to
suppress certificate checking.  This works around `cannot validate
certificate` errors from the `wsk` CLI.

If your deployment is not working, check our
[troubleshooting guide](./docs/troubleshooting.md) for ideas.


# Deploying OpenWhisk Providers

Now that you have a working OpenWhisk installation, you may optionally
deploy additional packages and event providers. A standard set of
event providers is available as a collection of Helm charts in the
`helm/providers` directory.  You may install all the providers in a
single command with
```shell
helm install ./helm/openwhisk-providers --namespace=openwhisk --name=owdev-providers
```
or you may selectively install the charts for individual providers
with commands like
```shell
helm install ./helm/openwhisk-providers/charts/ow-kafka --namespace=openwhisk --name=owdev-kafka-provider
```

Please see the `values.yaml` file and/or README.md in the individual
charts for instructions on enabling any optional customizations of the
providers.

# Development and Testing

This section outlines how common OpenWhisk development tasks are
supported when OpenWhisk is deployed on Kubernetes using Helm.

### Running OpenWhisk test cases

Some key differences in a Kubernetes-based deployment of OpenWhisk are
that deploying the system does not generate a `whisk.properties` file and
that the various internal microservices (`invoker`, `controller`,
etc.) are not directly accessible from the outside of the Kubernetes cluster.
Therefore, although you can run full system tests against a
Kubernetes-based deployment by giving some extra command line
arguments, any unit tests that assume direct access to one of the internal
microservices will fail.   The system tests can be executed in a
batch-style as shown below, where WHISK_SERVER and WHISK_AUTH are
replaced by the values returned by `wsk property get --apihost` and
`wsk property get --auth` respectively.
```shell
cd $OPENWHISK_HOME
./gradlew :tests:testSystemBasic -Dwhisk.auth=$WHISK_AUTH -Dwhisk.server=https://$WHISK_SERVER -Dopenwhisk.home=`pwd`
```
You can also launch the system tests as JUnit test from an IDE by
adding the same system properties to the JVM command line used to
launch the tests:
```shell
 -Dwhisk.auth=$WHISK_AUTH -Dwhisk.server=https://$WHISK_SERVER -Dopenwhisk.home=`pwd`
```

### Deploying a locally built docker image.

By overriding the default `image` and `imagePullPolicy` for one or
more OpenWhisk components, you can run locally built docker images.
For example, to use a locally built controller image, just add the
stanza below to your `mycluster.yaml` to override the default behavior
of pulling `openwhisk/controller:latest` from Docker Hub.
```yaml
controller:
  image: "whisk/controller"
  imagePullPolicy: "IfNotPresent"
```

### Selectively redeploying using a locally built docker image

You can use the `helm upgrade` command to selectively redeploy one or
more OpenWhisk componenets.  Continuing the example above, if you make
additional changes to the controller source code and want to just
redeploy it without redeploying the entire OpenWhisk system you can do
the following:
```shell
# Execute these commands in your openwhisk directory
./gradlew distDocker
docker tag whisk/controller whisk/controller:v2
```
Then, edit your `mycluster.yaml` to contain:
```yaml
controller:
  image: "whisk/controller:v2"
  imagePullPolicy: "IfNotPresent"
```
Redeploy with Helm by executing this commaned in your
openwhisk-deploy-kube directory:
```shell
helm upgrade ./helm/openwhisk --namespace=openwhisk --name=owdev -f mycluster.yaml
```

# Cleanup

Use the following command to remove all the deployed OpenWhisk components:
```shell
helm delete owdev
```
Helm does keep a history of previous deployments.  If you want to
completely remove the deployment from helm, for example so you can
reuse owdev to deploy OpenWhisk again, use the command:
```shell
helm delete owdev --purge
```

# Issues

If your OpenWhisk deployment is not working, check our
[troubleshooting guide](./docs/troubleshooting.md) for ideas.

Report bugs, ask questions and request features [here on GitHub](../../issues).

You can also join our slack channel and chat with developers. To get access to our slack channel, request an invite [here](http://slack.openwhisk.org).

# Disclaimer

Apache OpenWhisk Deployment on Kubernetes is an effort undergoing incubation at The Apache Software Foundation (ASF), sponsored by the Apache Incubator. Incubation is required of all newly accepted projects until a further review indicates that the infrastructure, communications, and decision making process have stabilized in a manner consistent with other successful ASF projects. While incubation status is not necessarily a reflection of the completeness or stability of the code, it does indicate that the project has yet to be fully endorsed by the ASF.
