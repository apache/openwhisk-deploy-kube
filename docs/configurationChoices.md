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

NOTE: The Helm-based deployment does not yet support setting the replicaCount
to be greater than 1 for the following components:
- apigateway
- couchdb
- kakfa
- kakfaprovider
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

### Using external Kafka and Zookeeper services

You may want to use an external Zookeeper or Kafka service.  To disable the kafka and/or zookeeper with this chart, add a stanza like the one below to your `mycluster.yaml`.
```yaml
kafka:
  external: true
zookeeper:
  external: true
```

To add the hostname of a pre-existing kafka and/or zookeeper, define it in `mycluster.yml` like this

```yaml
kafka:
  external: true
  name: < existing kafka service >
zookeeper:
  external: true
  name: < existing zookeeper service >

```

Optionally, if including this chart as a dependency of another chart where kafka and zookeeper services are already defined, disable this chart's kafka and zookeeper as shown above, and then define kafka_host, zookeeper_connect, and zookeeper_zero_host in your parent chart _helpers.tpl. e.g.
```
{{/* hostname for kafka */}}
{{- define "kafka_host" -}}
{{ template "kafka.serviceName" . }}
{{- end -}}

{{/* hostname for zookeeper */}}
{{- define "zookeeper_connect" -}}
{{ template "zookeeper.serviceName" . }}
{{- end -}}

{{/* zookeeper_zero_host required by openwhisk readiness check */}}
{{- define "zookeeper_zero_host" -}}
{{ template "zookeeper.serviceName" . }}
{{- end -}}
```

### Persistence

The couchdb, zookeeper, kafka, and redis microservices can each be
configured to use persistent volumes to store their data. Enabling
persistence may allow the system to survive failures/restarts of these
components without a complete loss of application state. By default,
none of these services is configured to use persistent volumes.  To
enable persistence, you can add stanzas like the following to your
`mycluster.yaml` to enable persistence and to request an appropriately
sized volume.

```yaml
redis:
  persistence:
    enabled: true
    size: 256Mi
    storageClass: default
```
If you are deploying to `minikube`, use the storageClass `standard`.
If you are deploying on a managed Kubernetes cluster, check the cloud
provider's documentation to determine the appropriate `storageClass`
and `size` to request.

Note that the Helm charts do not explicitly create the
PersistentVolumes to satisfy the PersistentVolumeClaims they
instantiate. We assume that either your cluster is configured to
support [Dynamic Volume Provision](https://kubernetes.io/docs/concepts/storage/dynamic-provisioning/)
or that you will manually create any necessary PersistentVolumes when
deploying the Helm chart.

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
You will also need to override the value of `whisk.containerPool.userMemory`
to a significantly larger value when using the KubernetesContainerFactory
to better match the overall memory available on invoker worker nodes divided by
the number of Invokers you are creating.
