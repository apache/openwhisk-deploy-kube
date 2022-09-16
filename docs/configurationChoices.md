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

NOTE: setting the replicaCount to be greater than 1 for the following
components is not currently supported:
- apigateway and redis. Running only a single replica of these services is
  unlikely to be a significant scalability bottleneck.
- couchdb. For production deployments of OpenWhisk on Kubernetes, we strongly recommend running
  CouchDB externally to OpenWhisk as described below. An external CouchDB instance enables
  better management of the database and decouples its lifecycle from that of the OpenWhisk deployment.
- The event providers: alarmprovider and kafkaprovider.

### Openwhisk Scheduler

By default, the scheduler is disabled. To enable the scheduler, add the following
to your `mycluster.yaml`

```yaml
scheduler:
  enabled: true
```

### Using an external database

You may want to use an external CouchDB or Cloudant instance instead
of deploying a CouchDB instance as a Kubernetes pod as part of the
same `helm install` as the rest of OpenWhisk. Using an external
database is especially useful in production scenarios as it decouples
the management of the database from that of the rest of the
system. Decoupling the database increases operational flexibility, for
example by enabling blue/green deployments of OpenWhisk using a shared
database instance.

To use an externally deployed database, add a stanza like the one
below to your `mycluster.yaml`, substituting in the appropriate values
for `<...>`
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

Please note, if you're using a version of CouchDB that has `require_valid_user` enabled, you need to disable it for the
cluster to operate correctly. This is because the current version of the cloudant client [expects it to be off by default](https://github.com/cloudant/python-cloudant/issues/387).

### Using an external redis

Similarly, you may want to use external Redis instance instead of using default single pod deployment.
This is especially useful in production scenarios as a HA Redis deployment is recommended.

To use an externally deployed Redis, add a stanza like the one
below to your `mycluster.yaml`, substituting in the appropriate values
for `<...>`

```yaml
redis:
  external: true
  host: <redis hostname or ip addr>
  port: <redis port>
```

### Using an external kafka/zookeeper

To use an externally deployed kafka/zookeeper instead of using default single pod deployment, add a stanza like the one
below to your `mycluster.yaml`, substituting in the appropriate values
for `<...>`

```yaml
zookeeper:
  external: true
  connect_string: <zookeeper connect string>
  host: <the first instance of zookeeper>

kafka:
  external: true
  connect_string: <kafka connect string>
```

### Using activation store backend: ElasticSearch

Currently, deploy-kube uses `CouchDB` for activation store backend by default,
If you want to change it to `ElasticSearch`, just change

```yaml
activationStoreBackend: "ElasticSearch"
```

If you want to use an externally deployed ElasticSearch for activation store backend, add a stanza like the one
below to your `mycluster.yaml`, substituting in the appropriate values
for `<...>`

```yaml
activationStoreBackend: "ElasticSearch"
elasticsearch:
  external: true
  connect_string: <elasticsearch connect string>
  protocol: <"http" or "https">
  host: <the first instance of elasticsearch>
  indexPattern: <the indexPattern for activation index>
  username: <elasticsearch username>
  password: <elasticsearch username>
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

See [NFS Dynamic Storage Provisioning](./k8s-nfs-dynamic-storage.md) for one
approach to provisioning dynamic storage if it's not already provisioned
on your cluster.

If your cluster is not thus configured and you want to use persistence,
then you will need to add the following stanza to your `mycluster.yaml`.

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
by adding the following stanza to your `mycluster.yaml`:

```yaml
k8s:
  persistence:
    enabled: false
```

Currently, etcd persistence is not supported.

### Selectively Deploying Event Providers

The default settings of the Helm chart will deploy OpenWhisk's alarm
and kafka event providers. If you want to disable the
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
      primary disadvantages are (1) that it does not leverage Kubernetes to
      simplify resource management, security configuration, etc. for
      user containers and (2) it cannot be used if the underlying
      container engine is containerd or cri-o.
  2. `KubernetesContainerFactory` is a truly Kubernetes-native design
      where although the Invoker is still responsible for managing the
      cache of available user containers, the Invoker relies on Kubernetes to
      create, schedule, and manage the Pods that contain the user function
      containers. The pros and cons of this design are roughly the
      inverse of `DockerContainerFactory`.  Kubernetes pod management
      operations have higher latency and without additional configuration
      (see below) can result in poor performance. However, this design
      fully leverages Kubernetes to manage the execution resources for
      user functions.

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

### User action container DNS

By default, your user actions containers will be configured to use the same
DNS nameservers, search path, and options as the Invoker pod that spawned them.
If you want to override this default when using the DockerContainerFactory,
you can set `invoker.containerFactory.networkConfig.dns.inheritInvokerConfig` to `false`
and explicitly configure the child values of `invoker.containerFactory.networkConfig.dns.overrides`
instead.

### User action container network isolation

By default, a set of NetworkPolicy objects will be configured to isolate
pods running user actions from each other and from the back-end pods
of the OpenWhisk control plane.  If you want to disable this network
isolation, set `invoker.containerFactory.kubernetes.isolateUserActions`
to `false`.

### Customizing probes setting

Many openwhisk components has liveness and readiness probes configured. Sometimes it is observed that components do not come up or in ready state before the probes starts executing which causes pods to restarts or fail. You can configure probes timing settings like `initialDelaySeconds`, `periodSeconds` and `timeoutSeconds` in `mycluster.yaml`

```bash
probes:
  zookeeper:
    livenessProbe:
      initialDelaySeconds: <number of seconds>
      periodSeconds: <number of seconds>
      timeoutSeconds: <number of seconds>
```

**Note:** currently, probes settings are available for `zookeeper` and `controllers` only.

### Metrics and prometheus support

OpenWhisk distinguishes between `system` and `user` metrics. System metrics typically contain information about system performance and use Kamon to collect. User metrics encompass information about action performance which is sent to Kafka in a form of events.

#### System metrics

If you want to collect system metrics, store and display them with prometheus, use below configuration in `mycluster.yaml`:

```
metrics:
  prometheusEnabled: true
```

This will automatically spin up a Prometheus server inside your cluster that will start scraping `controller` and `invoker` metrics.

You can access Prometheus by using port forwarding:
```
kubectl port-forward svc/owdev-prometheus-server 9090:9090 --namespace openwhisk
```

#### User metrics

If you want to enable user metrics, use the below configuration in `mycluster.yaml`:

```
metrics:
  userMetricsEnabled: true
```

This will install [User-events](https://github.com/apache/openwhisk/tree/master/core/monitoring/user-events), [Prometheus](https://github.com/prometheus/prometheus) and [Grafana](https://github.com/grafana/grafana) on your cluster with already preconfigured Grafana dashboards for visualizing user generated metrics.

The dashboards can be accessed here:
```
https://<whisk.ingress.apiHostName>:<whisk.ingress.apiHostPort>/monitoring/dashboards
```
All dashboards can be viewed anonymously and by default admin Grafana credentials are `admin/admin`. Use the bellow configuration in `mycluster.yaml` to change Grafana's admin password:
```
grafana:
  adminPassword: admin
```

# Configure pod disruptions budget

To avoid openwhisk components from [voluntary and nonvoluntary disruptions](https://kubernetes.io/docs/concepts/workloads/pods/disruptions/) which are managed by Kubernetes built-in controllers, you can configure PDB in `mycluster.yaml`.

```yaml
pdb:
  enable: true
  zookeeper:
    maxUnavailable: 1
  controller:
    maxUnavailable: 1
```

Currently, you can configure PDB for below components.

- Zookeeper
- Kafka
- Controller
- Invoker

**Notes:**

- You can specify numbers of maxUnavailable Pods for now as integer. % values are not
supported.
- minAvailable is not supported
- PDB only applicable when components replicaCount is > 1.
- Invoker PDB only applicable if containerFactory implementation is of type "kubernetes" and replicaCount is > 1.
