# OpenWhisk Deployment for Kubernetes

[![License](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](http://www.apache.org/licenses/LICENSE-2.0)
[![Build Status](https://travis-ci.org/apache/incubator-openwhisk-deploy-kube.svg?branch=master)](https://travis-ci.org/apache/incubator-openwhisk-deploy-kube)

This repo can be used to deploy OpenWhisk to a Kubernetes cluster.

# Table of Contents

* [Requirements](#requirements)
* [Setting up Kuberentes](#setting-up-kubernetes)
* [Configuring OpenWhisk](#configure-openwhisk)
* [Cleanup](#cleanup)
* [Limitations](#limitations)
* [Issues](#issues)

# Requirements
A number of requirements must be met for OpenWhisk to deploy on Kubernetes.

**Kubernetes**
* [Kubernetes](https://github.com/kubernetes/kubernetes) version 1.5+
* Kubernetes has [KubeDNS](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/) deployed
* (Optional) Kubernetes Pods can receive public addresses.
  This will be required if you wish to reach Nginx from outside
  of the Kubernetes cluster network.

**OpenWhisk**
* Docker version 1.12+

**NOTE:** If you do not have an environment that meets these requirements then you can
set one up following the [Setting up Kubernetes](#setting-up-kubernetes) section.

# Setting up Kubernetes

If you are deploying Kubernetes from scratch to try out OpenWhisk, there are a number of
ways to setup a Dev/Test environmnet depending on your host OS. To mitigate that, we are using
VirtualBox with a Ubuntu VM. For the full instructions on setting an environment up,
take a look at these [instructions](/docs/setting_up_kube/README.md).

# Configure OpenWhisk

To deploy OpenWhisk on Kubernetes, you first need to setup CouchDB.
In this repo, there is a CouchDB instance that can be used to standup
a small OpenWhisk test environment. We would not support using this
deployment strategy for production environments, but to test OpenWhisk
on Kube check out the CouchDB README.

* [CouchDB](kubernetes/couchdb/README.md)

For a production level CouchDB instance, take a look at the main
OpenWhisk [Docs](https://github.com/apache/incubator-openwhisk/blob/master/tools/db/README.md)
for CouchDB.

Once CouchDB has been successfully deployed, you will need
manually deploy the rest of the OpenWhisk components.

* [Zookeeper](kubernetes/zookeeper/README.md)
* [Kafka](kubernetes/kafka/README.md)
* [Controller](kubernetes/controller/README.md)
* [Invoker](kubernetes/invoker/README.md)
* [Nginx](kubernetes/nginx/README.md)

From here, you will now need to get the publicly available address
of Nginx. If you are using the default Nginx image with a NodePort
Service, then you can obtain the public IP using the following guide:

 1. Obtain the IP address of the Kubernetes nodes.

 ```
 kubectl get nodes
 ```

 2. Obtain the public port for the Kubernetes Nginx Service

 ```
 kubectl -n openwhisk describe service nginx
 ```

 From here you should note the port used for the api endpoint. E.g:

 ```
 export WSK_PORT=$(kubectl -n openwhisk describe service nginx | grep https-api | grep NodePort| awk '{print $3}' | cut -d'/' -f1)
 ```

Now you should be able to setup the wsk cli like normal and interact with
Openwhisk.

```
wsk property set --auth 23bc46b1-71f6-4ed5-8c54-816aa4f8c502:123zO3xZCLrMN6v2BKK1dXYFpXlPkccOFqm12CdAsMgRU4VrNZ9lyGVCGuMDGIwP --apihost https://[nginx_ip]:$WSK_PORT
```

Lastly, you will need to install the initial catalog. To do this, you will need
to set the `OPENWHISK_HOME` environment variable:

```
export OPENWHISK_HOME [location of the openwhisk repo]
```

Then you should be able to run the following commands. Just make sure to
replace the `[nginx_ip]` bellow.

```
  pushd /tmp
    git clone https://github.com/apache/incubator-openwhisk-catalog
    cd incubator-openwhisk-catalog/packages
    ./installCatalog.sh 789c46b1-71f6-4ed5-8c54-816aa4f8c502:abczO3xZCLrMN6v2BKK1dXYFpXlPkccOFqm12CdAsMgRU4VrNZ9lyGVCGuMDGIwP https://[nginx_ip]:$WSK_PORT
  popd
```

# Cleanup

At some point there might be a need to cleanup the Kubernetes environment.
For this, we want to delete all the OpenWhisk deployments, services, jobs
and whatever else might be there. For this, you can run the following script:

```
./configure/cleanup.sh
```
# Limitations

A couple of components for OpenWhisk on Kube deployment strategy requires custom
built Docker images. One such component is Nginx and currently resides at
[danlavine/whisk_nginx](https://hub.docker.com/r/danlavine/whisk_nginx/). There
is currently and open [issue](https://github.com/openwhisk/openwhisk/issues/2152)
to make a public image and once it is resolved, then we can switch to the public image.


**Bad Kube versions**
* Kube 1.6.3 has an issue with volume mount subpaths. See
  [here](https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG.md#v163)
  for more information.

## Enhancements

* Use a public Edge Docker image once this [issue](https://github.com/apache/incubator-openwhisk/issues/2152)
  is resolved

# Issues

Report bugs, ask questions and request features [here on GitHub](../../issues).

You can also join our slack channel and chat with developers. To get access to our slack channel, request an invite [here](http://slack.openwhisk.org).
