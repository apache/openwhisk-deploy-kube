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
[![Build Status](https://travis-ci.com/apache/openwhisk-deploy-kube.svg?branch=master)](https://travis-ci.com/github/apache/openwhisk-deploy-kube)
[![Join Slack](https://img.shields.io/badge/join-slack-9B69A0.svg)](http://slack.openwhisk.org/)

Apache OpenWhisk is an open source, distributed Serverless platform
that executes functions (fx) in response to events at any scale.  The
OpenWhisk platform supports a programming model in which developers
write functional logic (called Actions), in any supported programming
language, that can be dynamically scheduled and run in response to
associated events (via Triggers) from external sources (Feeds) or from
HTTP requests.

This repository supports deploying OpenWhisk to Kubernetes and OpenShift.
It contains a Helm chart that can be used to deploy the core
OpenWhisk platform and optionally some of its Event Providers
to both single-node and multi-node Kubernetes and OpenShift clusters.

# Table of Contents

* [Prerequisites: Kubernetes and Helm](#prerequisites-kubernetes-and-helm)
* [Deploying OpenWhisk](#deploying-openwhisk)
* [Administering OpenWhisk](#administering-openwhisk)
* [Development and Testing OpenWhisk on Kubernetes](#development-and-testing-openwhisk-on-kubernetes)
* [Cleanup](#cleanup)
* [Issues](#issues)

# Prerequisites: Kubernetes and Helm

[Kubernetes](https://kubernetes.io/) is a container orchestration
platform that automates the deployment, scaling, and management of
containerized applications. [Helm](https://helm.sh/) is a package
manager for Kubernetes that simplifies the management of Kubernetes
applications. You do not need to have detailed knowledge of either Kubernetes or
Helm to use this project, but you may find it useful to review their
basic documentation to become familiar with their key concepts and terminology.

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
development machine.  Configuring Docker with 4GB of memory and
2 virtual CPUs is sufficient for the default settings of OpenWhisk.
Depending on your host operating system, we recommend the following:
1. MacOS: Use the built-in Kubernetes support in Docker for Mac
version 18.06 or later. Please follow our
[setup instructions](docs/k8s-docker-for-mac.md) to initially create
your cluster.
2. Linux: Use [kind](https://github.com/kubernetes-sigs/kind).
Please follow our [setup instructions](docs/k8s-kind.md)
to initially create your cluster.
3. Windows: Use the built-in Kubernetes support in Docker for Windows
version 18.06 or later. Please follow our
[setup instructions](docs/k8s-docker-for-windows.md) to initially create
your cluster.

### Using a Kubernetes cluster from a cloud provider

You can also provision a Kubernetes cluster from a cloud provider,
subject to the cluster meeting the [technical
requirements](docs/k8s-technical-requirements.md). You will need at least
1 worker node with 4GB of memory and 2 virtual CPUs to deploy the default
configuration of OpenWhisk.  You can deploy to significantly larger clusters
by scaling up the replica count of the various components and labeling multiple
nodes as invoker nodes. We have
detailed documentation on using Kubernetes clusters from the following
major cloud providers:
* [IBM (IKS)](docs/k8s-ibm-public.md)
* [Google (GKE)](docs/k8s-google.md)
* [Amazon (EKS)](docs/k8s-aws.md)

We would welcome contributions of documentation for Azure (AKS) and any other public cloud providers.

### Using OpenShift

You will need at least 1 worker node with 4GB of memory and 2 virtual
CPUs to deploy the default configuration of OpenWhisk.  You can deploy
to significantly larger clusters by scaling up the replica count of
the various components and labeling multiple nodes as invoker nodes.
For more detailed documentation, see:
* [OpenShift 4](docs/openshift-4.md)

### Using a Kubernetes cluster you built yourself

If you are comfortable with building your own Kubernetes clusters and
deploying services with ingresses to them, you should also
be able to deploy OpenWhisk to a do-it-yourself cluster. Make sure
your cluster meets the [technical requirements](docs/k8s-technical-requirements.md).
You will need at least 1 worker node with 4GB of memory and 2 virtual CPUs to deploy
the default configuration of OpenWhisk.  You can deploy to
significantly larger clusters by scaling up the replica count of the
various components and labeling multiple nodes as invoker nodes.

Additional more detailed instructions:
* [Some general comments](docs/k8s-diy.md).
* [Using kubeadm on Ubuntu 18.04](docs/k8s-diy-ubuntu.md).

## Helm

[Helm](https://github.com/kubernetes/helm) is a tool to simplify the
deployment and management of applications on Kubernetes clusters.
The OpenWhisk Helm chart requires Helm 3.

Our automated testing currently uses Helm v3.2.4

Follow the Helm [install instructions](https://github.com/kubernetes/helm)
for your platform to install Helm v3.0.1 or newer.

# Deploying OpenWhisk

Now that you have your Kubernetes cluster and have installed
the Helm 3 CLI, you are ready to deploy OpenWhisk.

## Overview

You will use Helm to deploy OpenWhisk to your Kubernetes cluster.
There are four deployment steps that are described in more
detail below in the rest of this section.
1. [Initial cluster setup](#initial-setup). If you have provisioned a
multi-node cluster, you should label the worker nodes
to indicate their intended usage by OpenWhisk.
2. [Customize the deployment](#customize-the-deployment). You will
create a `mycluster.yaml` that specifies key facts about your
Kubernetes cluster and the OpenWhisk configuration you wish to
deploy. Predefined `mycluster.yaml` files for common flavors
of Kubernetes clusters are provided in the [deploy](./deploy)
directory.
3. [Deploy OpenWhisk with Helm](#deploy-with-helm). You will use Helm and
`mycluster.yaml` to deploy OpenWhisk to your Kubernetes cluster.
4. [Configure the `wsk` CLI](#configure-the-wsk-cli). You need to
tell the `wsk` CLI how to connect to your OpenWhisk deployment.

## Initial setup

### Single Worker Node Clusters

If your cluster has a single worker node, then you should
configure OpenWhisk without node affinity. This is done by adding
the following lines to your `mycluster.yaml`
```
affinity:
  enabled: false

toleration:
  enabled: false

invoker:
  options: "-Dwhisk.kubernetes.user-pod-node-affinity.enabled=false"
```

### Multi Worker Node Clusters

If you are deploying OpenWhisk to a cluster with multiple worker
nodes, we recommend using node affinity to segregate the compute nodes
used for the OpenWhisk control plane from those used to execute user
functions. Do this by labeling each node with
`openwhisk-role=invoker`. In the default configuration, which uses the
KubernetesContainerFactory, the node labels are used in conjunction
with Pod affinities to inform the Kubernetes scheduler how to place
work so that user actions will not interfere with the OpenWhisk
control plane.  When using the non-default DockerContainerFactory,
OpenWhisk assumes it has exclusive use of these invoker nodes and will
schedule work on them directly, completely bypassing the Kubernetes
scheduler. For each node
<INVOKER_NODE_NAME> you want to be an invoker, execute
```shell
kubectl label node <INVOKER_NODE_NAME> openwhisk-role=invoker
```

If you are targeting OpenShift, use the command
```shell
oc label node <INVOKER_NODE_NAME> openwhisk-role=invoker
```

For more precise control of the placement of the rest of OpenWhisk's
pods on a multi-node cluster, you can optionally label additional
non-invoker worker nodes. Use the label `openwhisk-role=core`
to indicate nodes which should run the OpenWhisk control plane
(the controller, kafka, zookeeeper, and couchdb pods).
If you have dedicated Ingress nodes, label them with
`openwhisk-role=edge`. Finally, if you want to run the OpenWhisk
Event Providers on specific nodes, label those nodes with
`openwhisk-role=provider`.

If the Kubernetes cluster does not allow you to assign a label to a
node, or you cannot use the affinity attribute, you use the yaml
snippet shown above in the single worker node configuration to disable
the use of affinities by OpenWhisk.

## Customize the Deployment

You will need a `mycluster.yaml` file to record key aspects of your
Kubernetes cluster that are needed to configure the deployment of
OpenWhisk to your cluster. For details, see the documentation
appropriate to your Kubernetes cluster:
* [Docker for Mac](docs/k8s-docker-for-mac.md#configuring-openwhisk)
* [Docker for Windows](docs/k8s-docker-for-windows.md#configuring-openwhisk)
* [kind](docs/k8s-kind.md#configuring-openwhisk)
* [IBM Cloud Kubernetes Service (IKS)](docs/k8s-ibm-public.md#configuring-openwhisk)
* [Google (GKE)](docs/k8s-google.md#configuring-openwhisk)
* [Amazon (EKS)](docs/k8s-aws.md#configuring-openwhisk)
* [OpenShift](docs/openshift-4.md##configuring-openwhisk)

Default/template `mycluster.yaml` for various types of Kubernetes clusets
can be found in subdirectories of [deploy](./deploy).

Beyond the basic Kubernetes cluster specific configuration information,
the `mycluster.yaml` file can also be used
to customize your OpenWhisk deployment by enabling optional features
and controlling the replication factor of the various microservices
that make up the OpenWhisk implementation. See the [configuration
choices documentation](./docs/configurationChoices.md) for a
discussion of the primary options.

## Deploy With Helm

For simplicity, in this README, we have used `owdev` as the release name and
`openwhisk` as the namespace into which the Chart's resources will be deployed.
You can use a different name and/or namespace simply by changing the commands
used below.

**NOTE:** The commands below assume Helm v3.2.0 or higher. Verify your local Helm version with the command `helm version`.

### Deploying Released Charts from Helm Repository

The OpenWhisk project maintains a Helm repository at `https://openwhisk.apache.org/charts`.
You may install officially released versions of OpenWhisk from this repository:

```
helm repo add openwhisk https://openwhisk.apache.org/charts
helm repo update
helm install owdev openwhisk/openwhisk -n openwhisk --create-namespace -f mycluster.yaml
```

### Deploying from Git

To deploy directly from sources, either download the
[latest source release](https://github.com/apache/openwhisk-deploy-kube/releases) or
`git clone https://github.com/apache/openwhisk-deploy-kube.git` and use the Helm chart
from the `helm/openwhisk` folder of the source tree.

```shell
helm install owdev ./helm/openwhisk -n openwhisk --create-namespace -f mycluster.yaml
```

### Checking status

You can use the command `helm status owdev -n openwhisk` to get a summary
of the various Kubernetes artifacts that make up your OpenWhisk
deployment. Once the pod name containing the word `install-packages` is in the `Completed` state,
your OpenWhisk deployment is ready to be used.

**NOTE:** You can check the status of the pod by running the following command `kubectl get pods -n openwhisk --watch`.

## Configure the wsk CLI

Configure the OpenWhisk CLI, wsk, by setting the auth and apihost
properties (if you don't already have the wsk cli, follow the
instructions [here](https://github.com/apache/openwhisk-cli)
to get it). Replace `whisk.ingress.apiHostName` and `whisk.ingress.apiHostPort`
with the actual values from your `mycluster.yaml`.
```shell
wsk property set --apihost <whisk.ingress.apiHostName>:<whisk.ingress.apiHostPort>
wsk property set --auth 23bc46b1-71f6-4ed5-8c54-816aa4f8c502:123zO3xZCLrMN6v2BKK1dXYFpXlPkccOFqm12CdAsMgRU4VrNZ9lyGVCGuMDGIwP
```
### Configuring the CLI for Kubernetes on Docker for Mac and Windows

The `docker0` network interface does not exist in the Docker for Mac/Windows
host environment. Instead, exposed NodePorts are forwarded from localhost
to the appropriate containers.  This means that you will use `localhost`
instead of `whisk.ingress.apiHostName` when configuring
the `wsk` cli and replace `whisk.ingress.apiHostPort`
with the actual values from your `mycluster.yaml`.

```shell
wsk property set --apihost localhost:<whisk.ingress.apiHostPort>
wsk property set --auth 23bc46b1-71f6-4ed5-8c54-816aa4f8c502:123zO3xZCLrMN6v2BKK1dXYFpXlPkccOFqm12CdAsMgRU4VrNZ9lyGVCGuMDGIwP
```

## Verify your OpenWhisk Deployment

Your OpenWhisk installation should now be usable.  You can test it by following
[these instructions](https://github.com/apache/openwhisk/blob/master/docs/actions.md)
to define and invoke a sample OpenWhisk action in your favorite programming language.

You can also issue the command `helm test owdev -n openwhisk` to run the basic
verification test suite included in the OpenWhisk Helm chart.

Note: if you installed self-signed certificates, which is the default
for the OpenWhisk Helm chart, you will need to use `wsk -i` to
suppress certificate checking.  This works around `cannot validate
certificate` errors from the `wsk` CLI.

If your deployment is not working, check our
[troubleshooting guide](./docs/troubleshooting.md) for ideas.

## Scale-up your OpenWhisk Deployment

Using defaults, your deployment is configured to provide a bare-minimum working platform for testing and exploration. For your specialized workloads, you can scale-up your openwhisk deployment by defining your deployment configurations in your `mycluster.yaml` which overrides the defaults in `helm/openwhisk/values.yaml`. Some important parameters to consider (for other parameters, check `helm/openwhisk/values.yaml` and [configurationChoices](./docs/configurationChoices.md)):
* `actionsInvokesPerminute`: limits the maximum number of invocations per minute.
* `actionsInvokesConcurrent`: limits the maximum concurrent invocations.
* `containerPool`: total memory available per `invoker` instance. `Invoker` uses this memory to create containers for user-actions. The concurrency-limit (actions running in parallel) will depend upon the total memory configured for `containerPool` and memory allocated per action (`default:` 256mb per container).

For more information about increasing concurrency-limit, check [scaling-up your deployment](./docs/k8s-custom-build-cluster-scaleup.md).

# Administering OpenWhisk

[Wskadmin](https://github.com/apache/openwhisk/tree/master/tools/admin) is the tool to perform various administrative operations against an OpenWhisk deployment.

Since wskadmin requires credentials for direct access to the database (that is not normally accessible to the outside), it is deployed in a pod inside Kubernetes that is configured with the proper parameters. You can run `wskadmin` with `kubectl`. You need to use the `<namespace>` and the deployment `<name>` that you configured with `--namespace` and `--name` when deploying.

You can then invoke `wskadmin` with:

```
kubectl -n <namespace> -ti exec <name>-wskadmin -- wskadmin <parameters>
```

For example, is your deployment name is `owdev` and the namespace is `openwhisk` you can list users in the `guest` namespace with:

```
$ kubectl -n openwhisk  -ti exec owdev-wskadmin -- wskadmin user list guest
23bc46b1-71f6-4ed5-8c54-816aa4f8c502:123zO3xZCLrMN6v2BKK1dXYFpXlPkccOFqm12CdAsMgRU4VrNZ9lyGVCGuMDGIwP
```

Check [here](https://github.com/apache/openwhisk/tree/master/tools/admin) for details about the available commands.

# Development and Testing OpenWhisk on Kubernetes

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
microservices will fail.   First clone the [core OpenWhisk repository](https://github.com/apache/openwhisk)
locally and set `$OPENWHISK_HOME` to its top-level directory. Then, the
system tests can be executed in a
batch-style as shown below, where WHISK_SERVER and WHISK_AUTH are
replaced by the values returned by `wsk property get --apihost` and
`wsk property get --auth` respectively.
```shell
cd $OPENWHISK_HOME
./gradlew :tests:testSystemKCF -Dwhisk.auth=$WHISK_AUTH -Dwhisk.server=https://$WHISK_SERVER -Dopenwhisk.home=`pwd`
```
You can also launch the system tests as JUnit test from an IDE by
adding the same system properties to the JVM command line used to
launch the tests:
```shell
 -Dwhisk.auth=$WHISK_AUTH -Dwhisk.server=https://$WHISK_SERVER -Dopenwhisk.home=`pwd`
```

**NOTE:** You need to install JDK 8 in order to run these tests.

### Deploying a locally built docker image.

If you are using Kubernetes in Docker, it is
straightforward to deploy local images by adding a stanza to your
mycluster.yaml. For example, to use a locally built controller image,
just add the stanza below to your `mycluster.yaml` to override the default
behavior of pulling a stable `openwhisk/controller` image from Docker Hub.
```yaml
controller:
  imageName: "whisk/controller"
  imageTag: "latest"
```

### Selectively redeploying using a locally built docker image

You can use the `helm upgrade` command to selectively redeploy one or
more OpenWhisk components.  Continuing the example above, if you make
additional changes to the controller source code and want to just
redeploy it without redeploying the entire OpenWhisk system you can do
the following:

If you are using a multi-node Kubernetes cluster you will need to
repeat the following steps on all nodes that may run the controller
component.

The first step is to rebuild the docker image:
```shell
# Execute this command in your openwhisk directory
bin/wskdev controller -b
```
Note that the ```wskdev``` flags ```-x``` and ```-d``` are not compatible
with the Kubernetes deployment of OpenWhisk.

Alternatively, you can build all of the OpenWhisk docker components:
```shell
# Execute this command in your openwhisk directory
./gradlew distDocker
```

After building the new docker image(s), tag the new image:
```shell
# Tag the docker image you seek to redeploy
docker tag whisk/controller whisk/controller:v2
```

Then, edit your `mycluster.yaml` to contain:
```yaml
controller:
  imageName: "whisk/controller"
  imageTag: "v2"
```
Redeploy with Helm by executing this command in your
openwhisk-deploy-kube directory:
```shell
helm upgrade owdev ./helm/openwhisk -n openwhisk -f mycluster.yaml
```

### Deploying Lean Openwhisk version.

To have a lean setup (no Kafka, Zookeeper and no Invokers as separate entities):
```yaml
controller:
  lean: true
```

# Cleanup

Use the following command to remove all the deployed OpenWhisk components:
```shell
helm uninstall owdev -n openwhisk
```
By default, `helm uninstall` removes the history of previous deployments.
If you want to keep the history, add the command line flag `--keep-history`.

# Issues

If your OpenWhisk deployment is not working, check our
[troubleshooting guide](./docs/troubleshooting.md) for ideas.

Report bugs, ask questions and request features [here on GitHub](../../issues).

You can also join our slack channel and chat with developers. To get access to our slack channel, request an invite [here](http://slack.openwhisk.org).
