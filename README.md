# OpenWhisk Deployment for Kubernetes

[![License](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](http://www.apache.org/licenses/LICENSE-2.0)
[![Build Status](https://travis-ci.org/apache/incubator-openwhisk-deploy-kube.svg?branch=master)](https://travis-ci.org/apache/incubator-openwhisk-deploy-kube)

This repository can be used to deploy OpenWhisk to a Kubernetes cluster.
To accomplish this, we have created a Kubernetes job responsible for
deploying OpenWhisk from inside of Kubernetes. This job runs through
the OpenWhisk Ansible playbooks with some modifications to "Kube-ify"
specific actions. The reason for this approach is to try and streamline
a one size fits all way of deploying OpenWhisk.

Currently, the OpenWhisk deployment is going to be a static set of
Kube yaml files. It should be easy to use the tools from this
repo to build your own OpenWhisk deployment job, allowing you to
set up your own configurations if need be.

The scripts and Docker images should be able to:

1. Build the Docker image used for deploying OpenWhisk.
2. Uses a Kubernetes job to deploy OpenWhisk.

# Table of Contents

* [Requirements](#requirements)
* [Setting up Kuberentes](#setting-up-kubernetes)
* [Configuring OpenWhisk](#configure-openwhisk)
* [Cleanup](#cleanup)
* [Troubleshooting](#troubleshooting)
* [Manually Building Custom Docker Files](#manually-building-custom-docker-files)
* [Limitations and Enhancements](#limitations-and-enhancements)
* [Issues](#issues)

# Requirements
A number of requirements must be met for OpenWhisk to deploy on Kubernetes.

**Kubernetes**
* Kubernetes version 1.5.6 and 1.6.2
  - https://github.com/kubernetes/kubernetes
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

We also have experimental support for
[Minikube](https://github.com/kubernetes/minikube), see the
[Minikube-specific install instructions](/minikube/README.md) for more details.

# Configure OpenWhisk

To configure OpenWhisk on Kubernetes, you will need to target a Kubernetes
environment. If you do not have one up and running, then you can look
at the [Setting up Kubernetes](#setting-up-kubernetes) section. Once you
are successfully up, running, and targetd, you will then need to create a
namespace called `openwhisk`. To do this, you can just run the following command.

```
kubectl apply -f configure/openwhisk_kube_namespace.yml
```

From here, you should just need to run the Kubernetes job to
setup the OpenWhisk environment. The only caveat is that
the default image is used to deploy to kube v1.5.6.
Take a look
[here](https://github.com/apache/incubator-openwhisk-deploy-kube/blob/master/configure/configure_whisk.yml#L19)
if you wish to change to kube v1.6.2 by replacing `v1.5.2` to `v1.6.2`.

**NOTE** Unfortunately Kube does not have backward compatibility
requirements between the cli and Kube api server. However,
the v1.5.6 image will probably work with any Kube v1.5+
and the v1.6.2 image will probably work with any Kube v1.6+.
If the configuration image does return compatibility
issues then try [building a custom image](#manually-building-custom-docker-files).

```
kubectl apply -f configure/configure_whisk.yml
```

To see what is happening during the deployment process, you can view
the logs from the configuration Pod creted by the previous command.

```
kubectl -n openwhisk logs configure-openwhisk-XXXXX
```

Once the configuration job successfully finishes, you will need
manually deploy the rest of the OpenWhisk components.
* [Zookeeper](kubernetes/zookeeper/README.md)
* [Kafka](kubernetes/kafka/README.md)
* [Controller](kubernetes/controller/README.md)
* [Invoker](kubernetes/invoker/README.md)
* [Nginx](kubernetes/nginx/README.md)

From here, you will now need to get the publicly available address
of Nginx.
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

At some point there might be a need to cleanup the Kubernetes
environment. For this, we want to delete all the OpenWhisk deployments,
services, jobs and whatever else might be there. For this, you can run the following script:

```
./kube_environment/cleanup.sh
```
# Troubleshooting
## Kafka

When inspecting kafka logs of various components and they are not able to
send/receive message then Kafka is the usual problem. If everything is deployed
on a single machine, then you might need to allow Kube Pods to communicate with
themselves over a Kube Service. Setting a network to promiscous mode can be the
solution will enable network traffic to route in a loop back to itself. E.g:

```
ip link set docker0 promisc on
```

## Kube RBAC

When deploying the configuration pod, if it fails with a
`error validating data: the server does not allow access to the requested resource;`
error then you probably do not have permissions to create Pods from a Pod running
in the Kube cluster. You will need to create a ClusterRoleBinding with proper
security settings. For information about the role bindings,
take a look at the info [here](https://kubernetes.io/docs/admin/authorization/rbac/).

# Manually Building Custom Docker Files

There are two images that are required when deploying OpenWhisk on Kube,
Nginx and the OpenWhisk configuration image. Right now the the configuration
images built will work with a Kube version 1.5.6 and 1.6.2. To build the
configuration image with a custom Kube version you can edit the build script
[here](https://github.com/apache/incubator-openwhisk-deploy-kube/blob/kube-1.6/docker/build.sh#L87-L88)

To build these images, there is a helper script that installs all
required dependencies and the Docker images themselves. For example,
one the required dependencies is the wsk cli and to build it you will need
to download the [OpenWhisk repo](https://github.com/openwhisk/openwhisk)
and setup your invironment to build the docker images via gradle. That
setup can be found [here](https://github.com/apache/incubator-openwhisk#native-development).

**Important**
To build custom docker images, you will need to be on a Linux machine.
During the `wsk` cli build process it mounts a number of files from the
host machine. Because of this, Golang determines that the `wsk` build
architecture should be for macOS, but of course this is the wrong version
when running later. It needs to be built for the Linux architecture.

To use the script, it takes in 2 arguments:
1. (Required) The first argument is the Docker account to push the built images
   to. For Nginx, it will tag the image as `account_name/whisk_nginx:latest`
   and the OpenWhisk configuration image will be tagged
   `account_name/whisk_config:dev-v1.5.6` and `account_name/whisk_config:dev-v1.6.2`.

   NOTE:  **log into Docker** before running the script or it will
   fail to properly upload the docker images.

2. (Optional) The second argument is the location of where the
    repo is installed locally. By default it assumes that this repo exists at
   `$HOME/workspace/openwhisk`.

If you plan on building your own images and would like to change from `danlavine's`,
then make sure to update the
[configure_whisk.yml](configure/configure_whisk.yml) and
[nginx](ansible-kube/environments/kube/files/nginx.yml) with your images.

To run the script, use the command:

```
docker/build <Docker username> <(optional) openwhisk dir>
```

# Editing the Openwhisk Kube Deployment
## Kubernetes Deployments and Services

The current Kube Deployment and Services files that define the OpenWhisk
cluster can be found [here](ansible-kube/environments/kube/files). Only one
instance of each OpenWhisk process is created, but if you would like
to increase that number, then this would be the place to do it. Simply edit
the appropriate file and
[Manually Build Custom Docker Files](#manually-building-custom-docker-files)

# Development
## Debugging OpenWhisk on Kubernetes Configuration Pod

When in the process of creating a new deployment, it is nice to
run things by hand to see what is going on inside the container and
not have it be removed as soon as it finishes or fails. For this,
you can change the command of [configure_whisk.yml](configure/configure_whisk.yml)
to `command: [ "tail", "-f", "/dev/null" ]`. Then just run the
original command from inside the Pod's container.

# Limitations and Enhancements
## Limitations

During the deployment process, OpenWhisk needs to generate a CA-cert
for Nginx and currently it has a static dns entry. Because of this, you
will need to connect to OpenWhisk using the insecure mode (e.g. `wsk -i`).
There is future work to make this CA-cert configurable.

A couple of components for OpenWhisk on Kube deployment strategy requires custom
built Docker images. One such component is Nginx and currently resides at
[danlavine/whisk_nginx](https://hub.docker.com/r/danlavine/whisk_nginx/). There
is currently and open [issue](https://github.com/openwhisk/openwhisk/issues/2152)
to make a public image and once it is resolved, then we can switch to the public image.

The second Docker image this deployment strategy relies on is the OpenWhisk
configuration image. For now, it is hosted at
[danlavine/whisk_config](https://hub.docker.com/r/danlavine/whisk_config/),
but ideally an official images can be built an maintained at some point.
If you would like to build your own deployment image, see
[Manually Build Custom Docker Files](#manually-building-custom-docker-files)

Lastly, since OpenWhisk is configured/deployed via a Kubernetes Pod it requires
the correct kubectl version to be built into `danlavine/whisk_config`. For now,
there is only a version for Kube 1.5, and one can be built for 1.6, but there
is no CI to test it against at the moment.

**Minikube (experimental)**
We also have experimental support for
* [Minikube](https://github.com/kubernetes/minikube), see the
* [Minikube-specific install instructions](/minikube/README.md) for more details.

**Bad Kube versions**
* Kube 1.6.3 has an issue with volume mount subpaths. See
  [here](https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG.md#v163)
  for more information.

## Enhancements

* Enable the configuration job to run any number of times. This way it updates an already running
  OpenWhisk deployment on all subsequent runs
* Use a public Edge Docker image once this [issue](https://github.com/apache/incubator-openwhisk/issues/2152)
  is resolved

# Issues

Report bugs, ask questions and request features [here on GitHub](../../issues).

You can also join our slack channel and chat with developers. To get access to our slack channel, request an invite [here](http://slack.openwhisk.org).
