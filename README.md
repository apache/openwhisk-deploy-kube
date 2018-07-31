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

This repository can be used to deploy OpenWhisk to a Kubernetes cluster.

# Table of Contents

* [Setting up Kubernetes and Helm](#setting-up-kubernetes-and-helm)
* [Deploying OpenWhisk](#deploying-openwhisk)
* [Deploying OpenWhisk Providers](#deploying-openwhisk-providers)
* [Cleanup](#cleanup)
* [Issues](#issues)

# Setting up Kubernetes and Helm

## Kubernetes

### Requirements

Several requirements must be met for OpenWhisk to deploy on Kubernetes.
* [Kubernetes](https://github.com/kubernetes/kubernetes) version 1.8+. However, multiple minor releases of Kubernetes, including 1.8.9 and 1.9.4 will not work for OpenWhisk due to bugs with volume mount subpaths (see[[kubernetes-61076](https://github.com/kubernetes/kubernetes/issues/61076)]). This bug will surface as a failure when deploying the nginx container.
* The ability to create Ingresses to make a Kubernetes service available outside of the cluster so you can actually use OpenWhisk.
* If you enable persistence (see [docs/configurationChoices.md](./docs/configurationChoices.md)), either your cluster is configured to support [Dynamic Volume Provision](https://kubernetes.io/docs/concepts/storage/dynamic-provisioning/) or you must manually create any necessary PersistentVolumes when deploying the Helm chart.
* Endpoints of Kubernetes services must be able to loopback to themselves (the kubelet's `hairpin-mode` must not be `none`).

### Using Minikube

For local development and testing, we recommend using Minikube with
the docker network in promiscuous mode.  Not all combinations of
Minikube and Kubernetes versions will work for running OpenWhisk.
Although other combinations may work, we recommend at least initially
using a combination from the table below that is verified by our
Travis CI testing.

| Kubernetes Version | Minikube Version |
--- | --- |
1.8.0 | 0.25.2 |
1.9.0 | 0.25.2 |

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
`192.168.99.100` and port 31001 is available to be used.

```yaml
whisk:
  ingress:
    type: NodePort
    api_host_name: 192.168.99.100
    api_host_port: 31001

nginx:
  httpsNodePort: 31001
```

Beyond specifying the ingress, the `mycluster.yaml` file is also used
to customize your OpenWhisk deployment by enabling optional features
and controlling the replication factor of the various micro-services
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
to get it). Replace `whisk.ingress.api_host_name` and `whisk.ingress.api_host_port`
with the actual values from your mycluster.yaml.
```shell
wsk property set --apihost whisk.ingress.api_host_name:whisk.ingress.api_host_port
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
helm install ./helm/providers --namespace=openwhisk --name=owdev-providers
```
or you may selectively install the charts for individual providers
with commands like
```shell
helm install ./helm/providers/charts/kafka --namespace=openwhisk --name=owdev-kafka-provider
```

Please see the `values.yaml` file and/or README.md in the individual
charts for instructions on enabling any optional customizations of the
providers.

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
