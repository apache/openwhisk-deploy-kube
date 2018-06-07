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

## Installing Helm

[Helm](https://github.com/kubernetes/helm) is a tool to simplify the
deployment and management of applications on Kubernetes clusters.  We
will use Helm to deploy OpenWhisk on Kubernetes.

Before you can use Helm, you need to do a small amount of one-time
setup on your Kubernetes cluster.

1. Make sure that you have a running Kubernetes cluster and a
`kubectl` client connected to this cluster as described in the
[Requirements section](../README.md#requirements) of the main
README.md.

2. Follow the Helm [install instructions](https://github.com/kubernetes/helm)
for your platform.

3. Run the following command to init `Helm Tiller`:
```shell
helm init
```

4. To see if Helm is ready, use the command below and make sure the
`tiller-deploy` pod is in the `Running` state.
```shell
kubectl get pods -n kube-system
```

5. Grant the necessary privileges to the `Helm` user:
```shell
kubectl create clusterrolebinding tiller-cluster-admin --clusterrole=cluster-admin --serviceaccount=kube-system:default
```

