# Setting Up Kubernetes

## Dev and Test Environment

For Dev/Test environments, it is always easiest to have a reproducible setup. The
current setup used for developing OpenWhisk on Kube solution is as follows.

VM Requirments:

* [VirtualBox](https://www.virtualbox.org/)
* [Ubuntu-14.04](https://www.ubuntu.com/download/alternative-downloads)
  Desktop or server should be fine. (We use desktop since it doubles as a Dev/Test env).

When creating the VM in virtualbox, it is always nice to give it more than enough
resource:

* 8GB Memory
* 100GB of Disk
* 4 Virtual Processors

Once the VM has been created, you will need to make sure that a number of tools
and packages have been installed:

* `sudo apt-get install git`
* Install the  [Docker](https://docs.docker.com/engine/installation/linux/ubuntu/#install-using-the-repository)
  repository, but do not install Docker itself. You will need version 1.12.6
  specifically which can be installed with:
  ```
  sudo apt-get install docker-engine=1.12.6~ubuntu-trusty
  ```
  once the repository has been set up
* [Golang 1.7.4](https://golang.org/dl/). Find the 1.7.4 version (same version to build Kubernetes
  so might as well go with it) and it will give details on setting up Golang.
* Download this repo
* (optional, reqired for dev) Download [openwhisk](https://github.com/apache/incubator-openwhisk)

Next, you will need to do some extra configurations since you are on a
VM. You will need to edit the `/etc/resolv.conf` file to point to a publicly
available DNS. Say:

```
nameserver 8.8.8.8
nameserver 8.8.4.4
```

The reason for this, is that Pods in Kubernetes mounts the hosts `resolv.conf`
file into the Pod as the `resolv.conf`. By default, Ubuntu has `nameserver 127.0.1.1`
which points to a loopback device. But in a Kube Pod that loopback
device is unreachable and makes no sense. There is a way to configure this in
Kubernetes, but the option is not exposed in the `local-up-cluster.sh` script
we will be using in just a minute.

Lastly, you will actually need to stand up the Kubernetes instance.
Luckily you should be able to run the travis setup script and have everything
be configured for you.

```
cd $THIS_REPO_LOCATION/.travis
TRAVIS_KUBE_VERSION=v1.5.6 TRAVIS_ETCD_VERSION=v3.0.14 ./setup
```

This script should download and install a correct version of `etcd`, `kubectl`, and the
[Kubernetes](https://github.com/kubernetes/kubernetes) repo. Then it will call
out to the `local-up-cluster.sh` script with extra configuration settings for
KubeDNS support inside of the Kube repo. That script then goes through
the process of install all of the binaries (If this fails recheck the Golang docs for setup)
and running them.

Once finished, you should be able to talk to the Kube repo using `kubectl`.

## Other Kube Configurations

[Kubeadm](https://kubernetes.io/docs/getting-started-guides/kubeadm/)
can be deployed with [Callico](https://www.projectcalico.org/) for the
[network](http://docs.projectcalico.org/v2.1/getting-started/kubernetes/installation/hosted/kubeadm/).
By default kubeadm runs with KubeDNS already enabled, but please make sure
to install Kubeadm for Kube version 1.5.

[Minikube](https://github.com/kubernetes/minikube) support is
experimental, see the
[Minikube-specific install instructions](/minikube/README.md) for more
details.
