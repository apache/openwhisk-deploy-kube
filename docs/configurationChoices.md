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
values in the `helm/openwhisk/values.yaml` file.

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

NOTE: The Helm-based deployment does not yet support setting the replicaCount
to be greater than 1 for the following components:
- apigateway
- couchdb
- kafka
- kafkaprovider
- nginx
- redis
We are actively working on reducing this list and would welcome PRs to help.

### Using an external database

You may want to use an external CouchDB or Cloudant instance instead
of deploying a CouchDB instance as a Kubernetes pod.  You can do this
by adding a stanza like the one below to your `mycluster.yaml`,
substituting in the appropriate values for `<...>`
```yaml
db:
  external: true
  host: <db hostname or ip addr>
  port: <db port>
  protocol: <"http" or "https">
  auth:
    username: <username>
    password: <password>
```

If your external database has already been initialized for use by OpenWhisk,
you can disable the Kubernetes Job that wipes and re-initializes the
database by adding the following to your `mycluster.yaml`
```yaml
db:
  wipeAndInit: false
```

### Persistence

Several of the OpenWhisk components that are deployed by the Helm
chart utilize PersistentVolumes to store their data.  This enables
that data to survive failures/restarts of those components without a
complete loss of application state.  To support this, the
couchdb, zookeeper, kafka, and redis deployments all generate
PersistentVolumeClaims that must be satisfied to enable their pods to
be scheduled.  If your Kubernetes cluster is properly configured to support
[Dynamic Volume Provision](https://kubernetes.io/docs/concepts/storage/dynamic-provisioning/),
including having a DefaultStorageClass admission controller and a
designated default StorageClass, then this will all happen seamlessly.

See [NFS Dynamis Storage Provisioning](./k8s-nfs-dynamic-storage.md) for one
approach to provisioning dynamic storage if it's not already provisioned
on your cluster.

If your cluster is not thus configured and you want to use persistence,
then you will need to add the following stanza to your mycluster.yaml.
```yaml
k8s:
  persistence:
    hasDefaultStorageClass: false
    explicitStorageClass: <DESIRED_STORAGE_CLASS_NAME>
```
If <DESIRED_STORAGE_CLASS_NAME> has a dynamic provisioner, deploying
the Helm chart will automatically create the required PersistentVolumes.
If <DESIRED_STORAGE_CLASS_NAME> does not have a dynamic provisioner,
then you will need to manually create the required persistent volumes.

Alternatively, you may also entirely disable the usage of persistence
by adding the following stanza to your mycluster.yaml:
```yaml
k8s:
  persistence:
    enabled: false
```

### Selectively Deploying Event Providers

The default settings of the Helm chart will deploy OpenWhisk's alarm,
cloudant, and kafka event providers. If you want to disable the
deployment of one or more event providers, you can add
a stanza to your `mycluster.yaml` for example:
```yaml
providers:
  alarm:
    enabled: false
```
will disable the deployment of the alarm provider.

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
      operations have higher latency and without additional configuration
      (see below) can result in poor performance. However, this design
      fully leverages Kubernetes to manage the execution resources for user functions.

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

For scalability, you will probably want to use `replicaCount` to
deploy more than one Invoker when using the KubernetesContainerFactory.
You will also need to override the value of `whisk.containerPool.userMemory`
to a significantly larger value when using the KubernetesContainerFactory
to better match the overall memory available on invoker worker nodes divided by
the number of Invokers you are creating.

When using the KubernetesContainerFactory, the invoker uses the Kubernetes
API server to extract logs from the user action containers.  This operation has
high overhead and if user actions produce non-trivial amounts of logging output
can result in a severe performance degradation. To mitigate this, you should
configure an alternate implementation of the LoggingProvider SPI.
For example, you can completely disable OpenWhisk's log processing and rely
on Kubernetes-level logs of the action containers by adding the following
to your `mycluster.yaml`:
```yaml
invoker:
  options: "-Dwhisk.spi.LogStoreProvider=org.apache.openwhisk.core.containerpool.logging.LogDriverLogStoreProvider"
```

The KubernetesContainerFactory can be deployed with an additional
invokerAgent that implements container suspend/resume operations on
behalf of a remote Invoker. To enable this experimental configuration, add
```yaml
invoker:
  containerFactory:
    impl: "kubernetes"
      agent:
        enabled: true
```
to your `mycluster.yaml`

### User action container DNS

By default, your user actions containers will be configured to use the same
DNS nameservers, search path, and options as the Invoker pod that spawned them.
If you want to override this default when using the DockerContainerFactory,
you can set `invoker.containerFactory.networkConfig.dns.inheritInvokerConfig` to `false`
and explicitly configure the child values of `invoker.containerFactory.networkConfig.dns.overrides`
instead.
