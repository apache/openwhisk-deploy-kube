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

This file documents some of the common things that can go wrong when
deploying OpenWhisk on Kubernetes and how to correct them.

### No invokers are deployed with DockerContainerFactory

Verify that you actually have at least one node with the label openwhisk-role=invoker.

### Invoker pods fail to start with volume mounting problems

To execute the containers for user actions, OpenWhisk relies on part
of the underlying infrastructure that Kubernetes is running on. When
deploying the Invoker for OpenWhisk, it mounts the host's Docker
socket and several other system-specific directories related to
Docker. This enables efficient container management, but it also also
means that the default volume hostPath values assume that the Kubernetes worker
node image is Ubuntu. If containers fail to start with errors related
mounting`/sys/fs/cgroup`, `/run/runc`,`/var/lib/docker/containers`, or
`/var/run/docker.sock`, then you will need to change the corresponding
value in `helm/openwhisk/templates/_invoker-helpers.yaml` to match the host operating system
running on your Kubernetes worker node.

### Invokers unhealthy when using DockerContainerFactory

It is becoming increasingly common for Kubernetes clusters to be
configured to be using something other than Docker as the underlying
container runtime engine (eg containerd or cri-o). The
DockerContainerFactory cannot be used on such clusters. The usual
symptom is that the invoker pods deploy correctly, but the controller
considers all invokers to be unheathy/down because even though the
invoker pod is running, it is unable to successfully spawn user action
containers.  The workaround is to use the KubernetesContainerFactory.

### Kafka, Redis, CouchDB, and Zookeeper pods stuck in Pending

These pods all mount Volumes via PersistentVolumeClaims. If there is a
misconfiguration related to the dynamic provisioning of
PersistentVolumes, then these pods will not be scheduled.  See the
Persistence section in the [configuration choices
documentation](./configurationChoices.md) for more details.

### Controller and Invoker cannot connect to Kafka

If services are having trouble connecting to Kafka, it may be that the
Kafka service didn't actually come up successfully. One reason Kafka
can fail to fully come up is that it cannot connect to itself. This can
happen if your kubelet's `hairpin-mode` is not `none`.

The usual symptom of this network misconfiguration is the controller
pod being in a CrashLoopBackOff where it exits before it reports
the successful creation of its `completed` topic.

Here's an example controller log of a successful startup:
```
[2018-10-18T17:53:48.129Z] [INFO] [#tid_sid_unknown] [Config] environment set value for kafka.hosts
[2018-10-18T17:53:48.130Z] [INFO] [#tid_sid_unknown] [Config] environment set value for port
[2018-10-18T17:53:49.360Z] [INFO] [#tid_sid_unknown] [KafkaMessagingProvider] created topic completed0
[2018-10-18T17:53:49.685Z] [INFO] [#tid_sid_unknown] [KafkaMessagingProvider] created topic health
[2018-10-18T17:53:49.929Z] [INFO] [#tid_sid_unknown] [KafkaMessagingProvider] created topic cacheInvalidation
[2018-10-18T17:53:50.151Z] [INFO] [#tid_sid_unknown] [KafkaMessagingProvider] created topic events
```
Here's what it looks like when the network is misconfigured and kafka is not really working:
```
[2018-10-18T17:30:37.309Z] [INFO] [#tid_sid_unknown] [Config] environment set value for kafka.hosts
[2018-10-18T17:30:37.310Z] [INFO] [#tid_sid_unknown] [Config] environment set value for port
[2018-10-18T17:30:53.433Z] [INFO] [#tid_sid_unknown] [Controller] Shutting down Kamon with coordinated shutdown
```

if you have `hairpin` mode configured but still seeing above error, this can happen due to probes failure as well. Default liveness probe for controller is 5 seconds, if you see similar error in controller logs, try customizing the prob settings to increase `initialDelaySeconds` for controller for liveness probe. See the customizing probes section in the [configuration choices documentation](./configurationChoices.md) for more details.

### wsk `cannot validate certificates` error

If you installed self-signed certificates, which is the default
for the OpenWhisk Helm chart, you will need to use `wsk -i` to
suppress certificate checking.  This works around `cannot validate
certificate` errors from the `wsk` CLI.

### nginx pod fails with `host not found in resolver` error

The nginx config map specifies a resolver that is used to resolve references to
Kubernetes services like the controller and apigateway into ip addresses. By default,
it uses `kube-dns.kube-system`. If your cluster instead uses `coredns` (or some other
dns subsystem), you will need to edit the `k8s.dns` entry in values.yaml to
an appropriate value for your cluster.  A misconfigured resolver will results in
the nginx pod entering a CrashLoopBackOff with an error message like the one below:
```
018/09/27 23:33:48 [emerg] 1#1: host not found in resolver "kube-dns.kube-system" in /etc/nginx/nginx.conf:41
nginx: [emerg] host not found in resolver "kube-dns.kube-system" in /etc/nginx/nginx.conf:41
```

### Install packages error `error: Package update failed`
If the install-packages-* pod Errors with a message like the below, ensure the `apiHost` you specify within `cluster.yaml` is resolvable within the cluster. You can check using `kubectl run --rm busybox-lookup -ti --image busybox -- nslookup <apiHost>`
```
Installing apimgmt package
error: Package update failed: Put https://...
```
