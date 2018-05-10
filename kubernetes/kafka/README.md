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

Kafka
-----

# Deploying

To deploy Kafka, you will need to make sure that [Zookeeper](../zookeeper/README.md)
is deployed. Otherwise Kafka will keep crashing since
it cannot sync to a cluster. To actually deploy Kafka,
just run:

```
kubectl apply -f kafka.yml
```

# Troubleshooting
## Networking errors

When inspecting kafka logs of various components and they are not able to
send/receive message then Kafka is the usual problem.  There are issues
when Kube Pods cannot communicate with themselves over a Kube Service.
Setting a network to promiscous mode can be the solution will enable network
traffic to route in a loop back to itself. E.g:

```
ip link set docker0 promisc on
```

**NOTE** The `docker0` network in the example above is the Pod network.
If you were using a CNI, then you would need to upgrade the CNI netowrk.

These fixes are of course only temporary fixes that can be used
when developing OpenWhisk on Kube. To deploy Kubernetes without the
need for for setting the network up with this manual fix, you need
to setup the Kubelet with `--hairpin-mode`.
