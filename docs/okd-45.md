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

# Deploying OpenWhisk on OKD/OpenShift 4.5

## Overview

The 4.5 version of OKD/OpenShift is based on Kubernetes 1.18.

We assume you have an operational cluster that meets the
[technical requirements](okd-technical-requirements.md) and that you
have sufficient privileges to perform the necessary `oc adm`
operations detailed below.

## Initial Setup

Create an openwhisk project (Kubernetes namespace) using the command
```shell
oc new-project openwhisk
```

Because OpenShift doesn’t allow arbitrary UIDs by default, execute the following commands:
```shell
oc adm policy add-scc-to-user anyuid -z default
oc adm policy add-scc-to-user privileged -z default
oc adm policy add-scc-to-user anyuid -z openwhisk-core
oc adm policy add-scc-to-user privileged -z openwhisk-core
oc adm policy add-scc-to-user anyuid -z owdev-init-sa
oc adm policy add-scc-to-user privileged -z owdev-init-sa
```

## Configuring OpenWhisk

You must use the KubernetesContainerFactory on OKD/OpenShift.

Here is a sample `mycluster.yaml`, where <DOMAIN_USED_IN_ROUTES_FOR_THIS_CLUSTER>
should be replaced with the domain used for Routes in your cluster.
```yaml
whisk:
  ingress:
    type: OpenShift
    apiHostName: openwhisk.<DOMAIN_USED_IN_ROUTES_FOR_THIS_CLUSTER>
    apiHostPort: 443
    apiHostProto: https
    domain: openwhisk.<DOMAIN_USED_IN_ROUTES_FOR_THIS_CLUSTER>
  testing:
    includeTests: false

invoker:
  containerFactory:
    impl: kubernetes
``

## Limitations

The nginx service is currently not deployed on OpenShift (problem
determining the appropriate value to use for `k8s.dns`, which is used to
set the resolver in `nginx-cm.yaml`).  As a result, the namespace
prefixed 'vanity url' rewriting routes and the download of the cli/SDK
binaries is not currently supported when deploying on OpenShift.

Smoketesting a deployment via `helm test` is not supported because
we did not use `helm install` to deploy the chart.
