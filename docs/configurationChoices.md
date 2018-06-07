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

This document outlines some of the configuration options that are
supported by the OpenWhisk Helm chart.  In general, you customize your
deployment by adding stanzas to `mycluster.yaml` that override default
values in the `helm/values.yaml` file.

### Replication factor

By default the OpenWhisk Helm Chart will deploy a single replica of each
of the micro-services that make up the OpenWhisk control plane. By
changing the `replicaCount` value for a service, you can instead deploy
multiple instances.  This can support both increased scalability and
fault tolerance. For example, to deploy two controller instances, add
the following to your `mycluster.yaml`

```yaml
controller:
  replicaCount: 2
```

### Invoker Container Factory

The Invoker is responsible for creating and managing the containers
that OpenWhisk creates to execute the user defined functions.  A key
function of the Invoker is to manage a cache of available warm
containers to minimize cold starts of user functions.
Architecturally, we support two options for deploying the Invoker
component on Kubernetes (selected by picking a
`ContainerFactoryProviderSPI` for your deployment).
  1. `DockerContainerFactory` matches the architecture used by the
      non-Kubernetes deployments of OpenWhisk.  In this approach, an
      Invoker instance runs on every Kubernetes worker node that is
      being used to execute user functions.  The Invoker directly
      communicates with the docker daemon running on the worker node
      to create and manage the user function containers.  The primary
      advantages of this configuration are lower latency on container
      management operations and robustness of the code paths being
      used (since they are the same as in the default system).  The
      primary disadvantage is that it does not leverage Kubernetes to
      simplify resource management, security configuration, etc. for
      user containers.
  2. `KubernetesContainerFactory` is a truly Kubernetes-native design
      where although the Invoker is still responsible for managing the
      cache of available user containers, the Invoker relies on Kubernetes to
      create, schedule, and manage the Pods that contain the user function
      containers. The pros and cons of this design are roughly the
      inverse of `DockerContainerFactory`.  Kubernetes pod management
      operations have higher latency and exercise newer code paths in
      the Invoker.  However, this design fully leverages Kubernetes to
      manage the execution resources for user functions.

You can control the selection of the ContainerFactory by adding either
```yaml
invoker:
  containerFactory:
    impl: "docker"
```
or
```yaml
invoker:
  containerFactory:
    impl: "kubernetes"
```
to your `mycluster.yaml`

The KubernetesContainerFactory can be deployed with an additional
invokerAgent that implements container suspend/resume operations on
behalf of a remote Invoker.  To enable this, add
```yaml
invoker:
  containerFactory:
    impl: "kubernetes"
      agent:
        enabled: true
```
to your `mycluster.yaml`

For scalability, you will probably want to use `replicaCount` to
deploy more than one Invoker when using the KubernetesContainerFactory.
