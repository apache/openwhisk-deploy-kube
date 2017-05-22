# OpenWhisk Deployment for Kubernetes

[![Build Status](https://travis-ci.org/apache/incubator-openwhisk-deploy-kube.svg?branch=master)](https://travis-ci.org/apache/incubator-openwhisk-deploy-kube)

This repo can be used to deploy OpenWhisk to a Kubernetes cluster.
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

## Requirements and Limitations
#### Limitations

As part of the deployment process, OpenWhisk needs to generate a CA-cert
for Nginx and currently it has a static dns entry. Because of this, you
will need to connect to OpenWhisk using the insecure mode (e.g. `wsk -i`).
There is future work to make this CA-cert configurable.

For now, OpenWhisk relies on part of the underlying infrastructure that Kube
is running on. When deploying the Invoker for OpenWhisk, it mounts the hosts
Docker socket. This way OpenWhisk can quickly provision actions and does not
have to run Docker inside of Docker.

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

#### Requirements

Because of the limitations mentioned above, all requirments to deploy OpenWhisk
on Kubernetes need to be met.

**Kubernetes**
* Kubernetes version 1.5.0-1.5.5
  - https://github.com/kubernetes/kubernetes
* Kubernetes has [KubeDNS](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/) deployed
* (Optional) Kubernetes Pods can receive public addresses.
  This will be required if you wish to reach Nginx from outside
  of the Kubernetes cluster's network.

**OpenWhisk**
* Docker version 1.12+

## Quick Start

To deploy OpenWhisk on Kubernetes, you will need to target a Kubernetes
environment. If you do not have one up and running, then you can look
at the [Local Kube Development](#local-kube-development) section
for setting one up. Once you are successfully targeted, you will need to create a
create a namespace called `openwhisk`. To do this, you can just run the
following command.

```
kubectl apply -f configure/openwhisk_kube_namespace.yml
```

From here, you should just need to run the Kubernetes job to
setup the OpenWhisk environment.

```
kubectl apply -f configure/configure_whisk.yml
```

To see what is happening during the deployment process,
you should be able to see the logs from the configuration VM.

```
kubectl -n openwhisk logs configure-openwhisk-XXXXX
```

Once the configuration job sucessfuly finishes, you should will need to
get the auth tokens used to setup OpenWhisk. As part of the deployment
process, we store these tokens in Kubernetes
[secrets](https://kubernetes.io/docs/concepts/configuration/secret/).
To get these tokens, you can run the following command:

```
kubectl -n openwhisk get secret openwhisk-auth-tokens -o yaml
```

To use the secrets you will need to base64 decode them. E.g:

```
export AUTH_SECRET=$(kubectl -n openwhisk get secret openwhisk-auth-tokens -o yaml | grep 'auth_whisk_system:' | awk '{print $2}' | base64 --decode)
```

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
wsk property set --auth $AUTH_SECRET --apihost https://[nginx_ip]:$WSK_PORT
```

## Manually Building Custom Docker Files

There are two images that are required when deploying OpenWhisk on Kube,
Nginx and the OpenWhisk configuration image.

To build these images, there is a helper script to build the
required dependencies and build the docker images itself. For example,
the wsk cli is built locally and then coppied into these images.

The script takes in 2 arguments:
1. (Required) The first argument is the Docker account to push the built images
   to. For Nginx, it will tag the image as `account_name/whisk_nginx:latest`
   and the OpenWhisk configuration image will be tagged `account_name/whisk_config:dev`.

   NOTE:  **log into Docker** before running the script or it will
   fail to properly upload the docker images.

2. (Optional) The second argument is the location of where the
   [OpenWhisk](https://github.com/openwhisk/openwhisk) repo is installed
   locally. By default it assumes that this repo exists at
   `$HOME/workspace/openwhisk`.

If you plan on building your own images and would like to change from `danlavine's`,
then make sure to update the
[configure_whisk.yml](configure/configure_whisk.yml) and
[nginx](ansible-kube/environments/kube/files/nginx.yml) with your images.

To run the script, use the command:

```
docker/build <username> <(optional) openwhisk dir>
```

## Editing the Openwhisk Kube Deployment
#### Kubernetes Deployments and Services

The current Kube Deployment and Services files that define the OpenWhisk
cluster can be found [here](ansible-kube/environments/kube/files). Only one
instance of each OpenWhisk process is created, but if you would like
to increase that number, then this would be the place to do it. Simply edit
the appropriate file and
[Manually Build Custom Docker Files](#manually-building-custom-docker-files)

## Development
#### Local Kube Development

There are a couple ways to bring up Kubernetes locally and currently we
are using the common `local-up-cluster.sh` script. Take a look at what
[travis](.travis/setup.sh) does to bring everything up with KubeDNS support.

[Kubeadm](https://kubernetes.io/docs/getting-started-guides/kubeadm/)
can be deployed with [Callico](https://www.projectcalico.org/) for the
[network](http://docs.projectcalico.org/v2.1/getting-started/kubernetes/installation/hosted/kubeadm/).
By default kubeadm runs with KubeDNS already enabled, but please make sure
to install Kubeadm for Kube version 1.5.

**Minikube is not supported** at this time because it uses an old version
of docker (1.11.x). See the the [Requirements and Limitations](#requirements-and-limitations)
section for more info.

#### Deploying OpenWhisk on Kubernetes

When in the process of creating a new deployment, it is nice to
run things by hand to see what is going on inside the container and
not have it be removed as soon as it finishes or fails. For this,
you can change the command of [configure_whisk.yml](configure/configure_whisk.yml)
to `command: [ "tail", "-f", "/dev/null" ]`. Then just run the
original command from inside the Pod's container.

#### Cleanup

As part of the development process, you might need to cleanup the Kubernetes
environment at some point. For this, we want to delete all the Kube deployments,
services and jobs. For this, you can run the following script:

```
./kube_environment/cleanup.sh
```
## Troubleshooting
#### Kafka

When deploying Kubernetes on Ubuntu 14.04 with the `local_up_cluster.sh` scripts,
you might need to allow kube pods to communicate with themselves over KubeDNS.
To enable this on the Docker network, you will need to run the following command:

```
ip link set docker0 promisc on
```

## Enhancements and TODOS

* Deploy OpenWhisk on Kubernetes 1.6+
* Allow users to provide custom certs for Nginx
* Enable the configuration job to run any number of times. This way it updates an already running
  OpenWhisk deployment on all subsequent runs
* Use a public Edge Docker image once this [issue](https://github.com/apache/incubator-openwhisk/issues/2152)
  is resolved


### Issues

Report bugs, ask questions and request features [here on GitHub](../../issues).

You can also join our slack channel and chat with developers. To get access to our slack channel, request an invite [here](http://slack.openwhisk.org).
