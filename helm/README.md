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

## Overview

This directory contains a Helm chart can be used to deploy Apache OpenWhisk to a Kubernetes cluster.

It currently does not support all of the options available in the more
manual deployment process described in the top-level README.md,
however we are actively working on closing the gaps.

The default values used in the chart are designed to deploy a minimal
OpenWhisk deployment suitable for local development or testing on
minikube or a single node Kubernetes cluster. We will soon provide a
second set of default values suitable for larger-scale deployments.

## Deployment Steps

Please follow the following steps in this section to use [Helm](https://github.com/kubernetes/helm) to deploy this chart.

### Step 1. Prepare Kubernetes and Helm

Make sure that you have a running Kubernetes cluster and a `kubectl`
client connected to this cluster as described in the [Requriements section](../README.md#requirements) of the main README.md.

### Step 2. Install and configure Helm

Then please install [Helm](https://github.com/kubernetes/helm) and run the following command to init `Helm Tiller`:
```shell
helm init

```

Please check with the following command to make sure `Helm` is up and running:
```shell
kubectl get pods -n kube-system

```

Then grant corresponding cluster role to `Helm` user:
```shell
kubectl create clusterrolebinding tiller-cluster-admin --clusterrole=cluster-admin --serviceaccount=kube-system:default
```

### Step 3. Prepare your cluster for OpenWhisk

1. Create a new namespace named `openwhisk`:
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

### Step 4. Define `mycluster.yaml`

You will need to create a mycluster.yaml file that records how the
OpenWhisk deployment on your cluster will be accessed by clients.  See
the [ingress discussion](./ingress.md) for details. Below is a sample
file appropriate for a minikube cluster where `minikube ip` returns
`192.168.99.100` and port 31001 is available to be used.

```yaml
whisk:
  ingress:
    type: NodePort
    api_host: 192.168.99.100:31001

nginx:
  httpsNodePort: 31001
```

### Step 5. Deploy Charts

Deployment can be done by using the following single command:
```shell
helm install . --namespace=openwhisk --name=your_release_name -f mycluster.yaml
```

After a while, if you can see all the pods listed by the following command are in `Running` state, congratulations, you have finished OpenWhisk deployment:
```shell
kubectl get pods -n openwhisk
```

### Step 6. Configure the `wsk` CLI

Configure the OpenWhisk CLI, wsk, by setting the auth and apihost
properties (if you don't already have the wsk cli, follow the
instructions [here](https://github.com/apache/incubator-openwhisk-cli)
to get it).
```shell
wsk property set --apihost <Value of whisk.ingress.api_host from mycluster.yaml>
wsk property set --auth 23bc46b1-71f6-4ed5-8c54-816aa4f8c502:123zO3xZCLrMN6v2BKK1dXYFpXlPkccOFqm12CdAsMgRU4VrNZ9lyGVCGuMDGIwP
```

### Step 7. Test your Deployment

Prepare a small js function like the following and save it to `greeting.js`:
```js
/**
 * Return a simple greeting message for someone.
 *
 * @param name A person's name.
 * @param place Where the person is from.
 */
function main(params) {
    var name = params.name || params.payload || 'stranger';
    var place = params.place || 'somewhere';
    return {payload:  'Hello, ' + name + ' from ' + place + '!'};
}
```

Create an OpenWhisk action by:
```shell
wsk action create hello ./greeting.js
```

And try this action:
```shell
wsk action invoke hello -b
```

If the action is invoked and message is returned without error, congratulations, you have a running OpenWhisk cluster on Kubernetes, enjoy it!

## Cleanup

Use the following command to remove the deployment:
```shell
helm delete <release_name>
```
or with a `--purge` option if you want to completely remove the deployment from helm:
```shell
helm delete <release_name> --purge
```

