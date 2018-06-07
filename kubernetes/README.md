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

# Manual deployment of OpenWhisk on Kubernetes

This file documents the pre-Helm procedures for deploying OpenWhisk on
Kubernetes.  We no longer recommend using this process, but there are
still a few configuration wrinkles that have not yet been ported to the
Helm chart.

## Initial Cluster Configuration

* Follow the steps for initial [Cluster Setup](cluster-setup)
* Configure your [Ingresses](ingress), including configuring the wsk CLI.

## Configure or Deploy CouchDB

Do one of the following:
* For development and testing purposes, this repo includes a configuration
  for deploying a [non-replicated CouchDB instance](couchdb)
  within the Kubernetes cluster.
* For a production level CouchDB instance, take a look at the main
  OpenWhisk [documentation for configuring CouchDB](https://github.com/apache/incubator-openwhisk/blob/master/tools/db/README.md).
  You will need to define the db.auth secret and db.config configmap as described in the [CouchDB README.md](couchdb/README.md)
  to match your database deployment and create a CouchDB service instance
  that forwards connections to your external database.

## Deploy Remaining Components

To deploy OpenWhisk on Kubernetes, you must deploy its components in
an order that respects their dependencies.  Detailed instructions and
the supporting configuration files can be found in the kubernetes
directory tree. Follow the instructions for each step in order.

* Deploy [ApiGateway](apigateway)
* Deploy [Zookeeper](zookeeper)
* Deploy [Kafka](kafka)
* Deploy [Controller](controller)
* Deploy [Invoker](invoker)
* Deploy [Nginx](nginx)

## Install system actions and the openwhisk catalog

* Install [RouteMgmt](routemgmt)
* Install [Package Catalog](openwhisk-catalog)

## Verify

Your OpenWhisk installation should now be usable.  You can test it by following
[these instructions](https://github.com/apache/incubator-openwhisk/blob/master/docs/actions.md)
to define and invoke a sample OpenWhisk action in your favorite programming language.

Note: if you installed self-signed certificates when you configured Nginx, you will need to use `wsk -i` to suppress certificate checking.  This works around `cannot validate certificate` errors from the `wsk` CLI.

# Cleanup

At some point there might be a need to cleanup the Kubernetes environment.
For this, we want to delete all the OpenWhisk deployments, services, jobs
and whatever else might be there. This is easily accomplished by
deleting the `openwhisk` namespace and all persistent volumes labeled with
pv-owner=openwhisk:

```
kubectl delete namespace openwhisk
kubectl delete persistentvolume -lpv-owner=openwhisk
```
