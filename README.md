# OpenWhisk Deployment for Kubernetes

[![License](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](http://www.apache.org/licenses/LICENSE-2.0)
[![Build Status](https://travis-ci.org/apache/incubator-openwhisk-deploy-kube.svg?branch=master)](https://travis-ci.org/apache/incubator-openwhisk-deploy-kube)

This repository can be used to deploy OpenWhisk to a Kubernetes cluster.

# Table of Contents

* [Requirements](#requirements)
* [Setting up Kubernetes](#setting-up-kubernetes)
* [Configuring OpenWhisk](#configuring-openwhisk)
* [Cleanup](#cleanup)
* [Issues](#issues)

# Requirements
Several requirements must be met for OpenWhisk to deploy on Kubernetes.

**Kubernetes**
* [Kubernetes](https://github.com/kubernetes/kubernetes) version 1.6+. However, avoid Kubernetes 1.6.3 due to an [issue with volume mount subpaths](https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG-1.6.md#known-issues-for-v163).  Our Travis CI testing uses Kubernetes version 1.7.4.
* The ability to create Ingresses to make a Kubernetes service available outside of the cluster so you can actually use OpenWhisk.
* Endpoints of Kubernetes services must be able to loopback to themselves ("hairpin mode").

**OpenWhisk**
* Docker version 1.12+

# Setting up Kubernetes

## Using Minikube

For local development and testing, we recommend using Minikube version 0.23+
with the docker network in promiscuous mode. Our Travis CI testing uses Minikube 0.23.0.
Take a look at these [instructions](/docs/setting_up_minikube/README.md).

## Using a Kubernetes cluster from a cloud provider

You can also provision a Kubernetes cluster from a cloud provider, subject to the cluster meeting the requirements above.

# Configuring OpenWhisk

The first time you deploy OpenWhisk on Kubernetes, we recommend
following the steps below manually so you can inspect the results and
debug your setup.  After you are confident that OpenWhisk deploys
smoothly on your cluster, you might find it useful to drive your
deployments using the script [build.sh](tools/travis/build.sh) that we
use to deploy OpenWhisk on Kubernetes for our Travis CI testing.

## Initial Cluster Configuration

* Follow the steps for initial [Cluster Setup](kubernetes/cluster-setup)
* Configure your [Ingresses](kubernetes/ingress), including configuring the wsk CLI.

## Configure or Deploy CouchDB

Do one of the following:
* For development and testing purposes, this repo includes a configuration
  for deploying a [simple non-persistent CouchDB instance](kubernetes/couchdb)
  within the Kubernetes cluster.
* For a production level CouchDB instance, take a look at the main
  OpenWhisk [documentation for configuring CouchDB](https://github.com/apache/incubator-openwhisk/blob/master/tools/db/README.md).
  You will need to define the db.auth secret and db.config configmap as described in the [CouchDB README.md](kubernetes/couchdb/README.md)
  to match your database deployment.

## Deploy Remaining Components

To deploy OpenWhisk on Kubernetes, you must deploy its components in
an order that respects their dependencies.  Detailed instructions and
the supporting configuration files can be found in the kubernetes
directory tree. Follow the instructions for each step in order.

* Deploy [ApiGateway](kubernetes/apigateway)
* Deploy [Zookeeper](kubernetes/zookeeper)
* Deploy [Kafka](kubernetes/kafka)
* Deploy [Controller](kubernetes/controller)
* Deploy [Invoker](kubernetes/invoker)
* Deploy [Nginx](kubernetes/nginx)

## Install system actions and the openwhisk catalog

* Install [RouteMgmt](kubernetes/routemgmt)
* Install [Package Catalog](kubernetes/openwhisk-catalog)

## Verify

Your OpenWhisk installation should now be usable.  You can test it by following
[these instructions](https://github.com/apache/incubator-openwhisk/blob/master/docs/actions.md)
to define and invoke a sample OpenWhisk action in your favorite programming language.

Note: if you installed self-signed certificates when you configured Nginx, you will need to use `wsk -i` to suppress certificate checking.  This works around `cannot validate certificate` errors from the `wsk` CLI.

# Cleanup

At some point there might be a need to cleanup the Kubernetes environment.
For this, we want to delete all the OpenWhisk deployments, services, jobs
and whatever else might be there. This is easily accomplished by
deleting the `openwhisk` namespace:

```
kubectl delete namespace openwhisk
```

# Issues

Report bugs, ask questions and request features [here on GitHub](../../issues).

You can also join our slack channel and chat with developers. To get access to our slack channel, request an invite [here](http://slack.openwhisk.org).
