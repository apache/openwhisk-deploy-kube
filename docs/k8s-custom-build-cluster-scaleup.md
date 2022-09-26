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

# Scaling-up OpenWhisk Deployment on custom-built-kubernetes cluster

## Overview

The default configurations of openwhisk deployment, support low concurrency-limit which can only be used for testing purposes. This document outlines how this concurrency-limit can be increased to scale-up openwhisk deployment for more practical use, on custom-built-kubernetes cluster. Also, provides information regarding some issues one might encounter while scaling-up.

## Scale-up

### Small Scale

By default, openwhisk deployment is configured to provide a bare-minimum working platform for testing and exploration. For your specialized workloads, you can scale-up your openwhisk deployment by defining your deployment configurations in your `mycluster.yaml` which overrides the defaults in `helm/openwhisk/values.yaml`. Some important parameters to consider (for other parameters, check `helm/openwhisk/values.yaml` and [configurationChoices](./docs/configurationChoices.md)):
* `actionsInvokesPerminute`: limits the maximum number of invocations per minute.
* `actionsInvokesConcurrent`: limits the maximum concurrent invocations.
* `containerPool.userMemory`: total memory available per `invoker` instance. `Invoker` uses this memory to create containers for user-actions. The concurrency-limit (actions running in parallel) will depend upon the total memory configured for `containerPool` and memory allocated per action (`default:` 256mb per container).
* `triggersFiresPerminute`: limits the maximum triggers invoked per minute.

Modifying the above mentioned parameters, one can easily increase the concurrency-limit (`default:` 8) to `100` or `200` without affecting the runtime performance (may vary based on the running functions). To further increase the concurrency-limit, check `Large` scale-up below.

### Large Scale

In order to further increase the scale-up beyond `Small Scale`, one needs to modify the following additional configurations appropriately (on top of the above mentioned):
* `invoker:jvmHeapMB`: jvmHeap memory available to each invoker instance. May or may not require increase based on running functions. For more information check `troubleshooting` below.
* `invoker:containerFactory:_:replicaCount`: number of invoker instances that will be used to handle the incoming workload. By default, there is only one invoker instance which can become overwhelmed if workload goes beyond a certain threshold.
* `controller:replicaCount`: number of controller instances that will be used to handle the incoming workload. Same as invoker and scheduler instances.
* `invoker:options`: Log processing at the invoker can become a bottleneck for the KubernetesContainerFactory. One might try disabling invoker log processing by setting it to `-Dwhisk.spi.LogStoreProvider=org.apache.openwhisk.core.containerpool.logging.LogDriverLogStoreProvider`. In general, one needs to offload log processing from the invoker to a node-level log store provider if one is trying to push a large load through the system.

## Troubleshooting

### Client-side

On the client-side, the most frequently received error:
```
"error": "The server is currently unavailable (because it is overloaded or down for maintenance).
```
The above mentioned error occurs when controller is unable to find any healthy invoker instance to serve the incoming requests. To resolve this issue, one needs to debug the `Deployment-side` to figure-out the cause for unhealth invoker instances.

### Deployment-side

For debugging, one needs to identify the `invoker` and `controller` pods and check their logs for further details. Few known errors:
```
class io.fabric8.kubernetes.client.KubernetesClientTimeoutException - Timed out waiting for [0] milliseconds for [Pod] with name
```
The above error occurs when one has configured too large a `containerPool` to match the incoming workloads, without configuring the scale-up for the invoker instance(s) to keep up with the serving rate.

```
java.lang.OutOfMemoryError: Java heap space
```
The above error occurs when the configured `invoker:jvmHeapMB` memory is insufficient for the faced workload.

#### error: only single invoker instance being used to handle all the workload

OpenWhisk treats [blackbox (docker) actions](https://github.com/apache/openwhisk/blob/master/docs/actions-docker.md) differently when compared to regular actions. By default, OpenWhisk loadbalancer is configured to use only `10%` (only 1 invoker-instance if total invoker-instances are less than 10) of invoker instances for `blackbox` actions. This behavior can be configured by modifying `whisk.loadbalancer.blackbox-fraction` in `helm/openwhisk/values.yaml`.


