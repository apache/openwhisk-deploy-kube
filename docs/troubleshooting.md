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

### Invokers containers fail to start with volume mounting problems

To execute the containers for user actions, OpenWhisk relies on part
of the underlying infrastructure that Kubernetes is running on. When
deploying the Invoker for OpenWhisk, it mounts the host's Docker
socket and several other system-specific directories related to
Docker. This enables efficient container management, but it also also
means that the default volume hostPath values assume that the Kubernetes worker
node image is Ubuntu. If containers fail to start with errors related
mounting`/sys/fs/cgroup`, `/run/runc`,`/var/lib/docker/containers`, or
`/var/run/docker.sock`, then you will need to change the corresponding
value in `helm/templates/invoker.yaml` to match the host operating system
running on your Kubernetes worker node.

### Controller and Invoker cannot connect to Kafka

If services are having trouble connecting to Kafka, it may be that the
Kafka service didn't actually come up successfully. One reason Kafka
can fail to come up is that it cannot connect to itself.  On minikube,
fix this by saying `minikube ssh -- sudo ip link set docker0 promisc
on`. If using kubeadm-dind-cluster, set `USE_HAIRPIN=true` in your environment
before running 'dind-cluster.sh up`. On full scale Kubernetes clusters,
make sure that your kubelet's `hairpin-mode` is not `none`).

### wsk `cannot validate certificates` error

If you installed self-signed certificates, which is the default
for the OpenWhisk Helm chart, you will need to use `wsk -i` to
suppress certificate checking.  This works around `cannot validate
certificate` errors from the `wsk` CLI.
