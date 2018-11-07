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

This repository can be used to deploy OpenWhisk to Kubernetes.
It contains Helm charts, documentation, and supporting
configuration files and scripts that can be used to deploy OpenWhisk
to both single-node and multi-node Kubernetes clusters.

# Table of Contents

* [Prerequisites: Kubernetes and Helm](#prerequisites-kubernetes-and-helm)
* [Deploying OpenWhisk](#deploying-openwhisk)
* [Deploying OpenWhisk Providers](#deploying-openwhisk-providers)
* [Development and Testing](#development-and-testing)
* [Cleanup](#cleanup)
* [Issues](#issues)

# Prerequisites: Kubernetes and Helm

[Kubernetes](https://kubernetes.io/) is a container orchestration
platform that automates the deployment, scaling, and management of
containerized applications. [Helm](https://helm.sh/) is a package
manager for Kubernetes that simplifies the management of Kubernetes
applications. You do not need to be an expert on either Kubernetes or
Helm to use this project, but you may find it useful to review their
overview documentation at the links above to become familiar with
their key concepts and terminology.

## Kubernetes

Your first step is to create a Kubernetes cluster that is capable of
supporting an OpenWhisk deployment. Although there are some [technical
requirements](docs/k8s-technical-requirements.md) that the Kubernetes
cluster must satisfy, any of the options described below is
acceptable.

### Simple Docker-based options

The simplest way to get a small Kubernetes cluster suitable for
development and testing is to use one of the Docker-in-Docker
approaches for running Kubernetes directly on top of Docker on your
development machine. Depending on your host operating system, we
recommend the following:
1. MacOS: Use the built-in Kubernetes support in Docker for Mac
version 18.06 or later. Please follow our
[setup instructions](docs/k8s-docker-for-mac.md) to initially create
your cluster.
2. Linux: Use kubeadm-dind-cluster, but carefully follow our
[setup instructions](docs/k8s-dind-cluster.md) because the default
setup of kubeadm-dind-cluster does *not* meet the requirements for
running OpenWhisk.
3. Windows: We believe that just like with MacOS, the built-in
Kubernetes support in Docker for Windows version 18.06 or later should
be sufficient to run OpenWhisk.  We would welcome a pull request with
provide detailed setup instructions for Windows.

### Using Minikube

Minikube provides a Kubernetes cluster running inside a virtual
machine (for example VirtualBox). It can be used on MacOS, Linux, or
Windows to run OpenWhisk, but is somewhat more finicky than the
docker-in-docker options described above. For details on setting up
Minikube, see these [instructions](docs/k8s-minikube.md).

### Using a Kubernetes cluster from a cloud provider

You can also provision a Kubernetes cluster from a cloud provider,
subject to the cluster meeting the [technical
requirements](docs/k8s-technical-requirements.md).  Managed
Kubernetes services from IBM (IKS), Google (GKE), and Amazon (EKS) are
known to work for running OpenWhisk and are all documented and
supported by this project.  We would welcome contributions of
documentation for Azure (AKS) and any other public cloud providers.

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

Now that you have your Kubernetes cluster and have installed and
initialized Helm, you are ready to deploy OpenWhisk.

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

You must create a `mycluster.yaml` file to record key aspects of your
Kubernetes cluster that are needed to configure the deployment of
OpenWhisk to your cluster. Most of the needed configuration is related
to networking and is described in the [ingress discussion](./docs/ingress.md).

Beyond specifying the ingress, the `mycluster.yaml` file is also used
to customize your OpenWhisk deployment by enabling optional features
and controlling the replication factor of the various microservices
that make up the OpenWhisk implementation. See the [configuration
choices documentation](./docs/configurationChoices.md) for a
discussion of the primary options.

### Sample mycluster.yaml for Docker for Mac

Here is a sample file for a Docker for Mac deployment where
`kubectl describe nodes | grep InternalIP` returns 192.168.65.3 and port 31001 is available to
be used on your host machine.
```yaml
whisk:
  ingress:
    type: NodePort
    apiHostName: 192.168.65.3
    apiHostPort: 31001

nginx:
  httpsNodePort: 31001
```

### Sample mycluster.yaml for kubeadm-dind-cluster.sh

Here is a sample file for a kubeadm-dind-cluster where `kubectl describe node kube-node-1 |
grep InternalIP` returns 10.192.0.3 and port 31001 is available to
be used on your host machine.
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
```

Note the stanza setting `invoker.containerFactory.dind` to `true`.
This stanza is required; failure to override the default of `false` inherited
from `helm/openwhisk/values.yaml` will result in a deployment
of OpenWhisk with no healthy invokers (and thus a deployment that
will not execute any user actions).

### Sample mycluster.yaml for Minikube

Here is a sample file appropriate for a Minikube cluster where
`minikube ip` returns `192.168.99.100` and port 31001 is available to
be used on your host machine.

```yaml
whisk:
  ingress:
    type: NodePort
    apiHostName: 192.168.99.100
    apiHostPort: 31001

nginx:
  httpsNodePort: 31001
```

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
wsk property set --apihost <whisk.ingress.apiHostName>:<whisk.ingress.apiHostPort>
wsk property set --auth 23bc46b1-71f6-4ed5-8c54-816aa4f8c502:123zO3xZCLrMN6v2BKK1dXYFpXlPkccOFqm12CdAsMgRU4VrNZ9lyGVCGuMDGIwP
```
### Configuring the CLI for Kubernetes on Docker for Mac

The `docker0` network interface does not exist in the Docker for Mac
host environment. Instead, exposed NodePorts are forwarded from localhost
to the appropriate containers.  This means that you will use `localhost`
instead of `whisk.ingress.apiHostName` when configuring
the `wsk` cli and replace `whisk.ingress.apiHostPort`
with the actual values from your mycluster.yaml.

```shell
wsk property set --apihost localhost:<whisk.ingress.apiHostPort>
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

If you are using Kubernetes in Docker, it is
straightforward to deploy local images by adding a stanza to your
mycluster.yaml. For example, to use a locally built controller image,
just add the stanza below to your `mycluster.yaml` to override the default
behavior of pulling `openwhisk/controller:latest` from Docker Hub.
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
