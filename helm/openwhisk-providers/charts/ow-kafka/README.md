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

# Use Helm to deploy kafka provider and package

This chart is to deploy the kafka provider and package to OpenWhisk on a Kubernetes using Helm.

## Config a CouchDB instance

A CouchDB instance is required to save the event data. You can use the same CouchDB instance as part of the OpenWhisk deployment or you can use a different CouchDB instance. To use the same CouchDB instance as OpenWhisk, config `values.yaml` as:
```
db:
  external: false
  prefix: "kp"
```
To use a different CouchDB instance, config the database parameters in `value.yaml` as:
```
db:
  external: true
  prefix: "kp"
  host: "0.0.0.0"
  port: 5984
  protocol: "http"
  username: "admin"
  password: "secret"
```

## Enable action containers to use Kubernetes DNS

You need to enable action containers to use Kubernetes DNS under one of below conditions:
+ you use the same CouchDB instance as part of the OpenWhisk deployment to save event data;
+ you intend to use Kubernetes DNS name to locate a Kafka instance as the Kafka event provider.

The easiest way to do this is to use the `KubernetesContainerFactory` as the [Invoker Container Factory](https://github.com/apache/incubator-openwhisk-deploy-kube/blob/master/docs/configurationChoices.md#invoker-container-factory) in the Kubernetes cluster by adding below configuration in the `mycluster.yaml` when you deploy OpenWhisk with Helm:
```
# Invoker configurations
invoker:
  containerFactory:
    impl: "kubernetes"
```
If you want to use the `DockerContainerFactory` you can instead attempt to configure the invoker to use Kubernetes DNS. First you can get the IP address of Kubernetes DNS server by `echo $(kubectl get svc kube-dns -n kube-system -o 'jsonpath={.spec.clusterIP}')` and then add below configuration in the `mycluster.yaml`:
```
# Invoker configurations
invoker:
  kubeDNS: "<IP_Address_Of_Kube_DNS>"
```

## Install

You may install this chart with command like
```
helm install ./helm/providers/charts/kafka --namespace=openwhisk --name owdev-kafka-provider
```

You can use `helm status owdev-kafka-provider` to check the status. When you see pod is running and job is completed, it should be ready to use.
