Invoker
-------

# Deploying

When deploying the Invoker, it needs to be deployed via a
[StatefulSet](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/).
This is because each Invoker instance needs to know the instance
it is for the Kafka topic. The current deployment is a single
Invoker instance and can be deployed with:

```
kubectl apply -f invoker.yml
```

**Important**

OpenWhisk relies on part of the underlying infrastructure that Kube
is running on. When deploying the Invoker for OpenWhisk, it mounts the hosts
Docker socket and a number of other components. This way OpenWhisk can
quickly provision actions and does not have to run Docker inside of Docker.
However, this also means that a number of the default mount options assume
that the Kubernetes host image is Ubuntu. During the deploy there could be an
issue and if the Invoker fails to deploy, see the [Troubleshooting](#troubleshooting)
section below.

# Invoker Deployment Changes
## Increase Invoker Count

To increase the number of Invokers, edit the
[replicas](https://github.com/apache/incubator-openwhisk-deploy-kube/tree/master/kubernetes/invoker/invoker.yml#L27)
line. Secondly, you will need to update the
[INVOKER_COUNT](https://github.com/apache/incubator-openwhisk-deploy-kube/tree/master/kubernetes/invoker/invoker.yml#L63-L64)
to with the same replica count.

## Deploying Invoker to Specific Kube Nodes

To deploy an Invoker to specific Kube nodes, you will need to edit the
[invoker.yml](https://github.com/apache/incubator-openwhisk-deploy-kube/tree/master/kubernetes/invoker/invoker.yml)
file with Kubernetes [NodeSelectors](https://kubernetes.io/docs/concepts/configuration/assign-pod-node/).

# Troubleshooting
## Deploying to Minikube

When deploying the Invoker to [Minikube](https://kubernetes.io/docs/getting-started-guides/minikube/)
you might need to edit the Invoker's Docker Api Version.
This is because Minikube uses Docker version 1.11.x.
To do this, you will need to add the following properties
to the invoker.yml file.

```
env:
  - name: "DOCKER_API_VERSION"
    value: "1.23"
```
## Kubernetes Host Linux Versions

Unfortunitaly when Deploying OpenWhisk on Kubernetes it currently mounts some
of the host OS files for the Invoker process and needs to make some assumptions.
Because of this, some failures are known to happen on certain Linux versions,
like CoreOs. If you see an error like:

```
Failed to start container with id 8d9125bf2d3711312a98a8b98de15306e495883cc470a03beb6689b34895791f with error: rpc error: code = 2 desc = failed to start container "8d9125bf2d3711312a98a8b98de15306e495883cc470a03beb6689b34895791f": Error response from daemon: {"message":"mkdir /usr/lib/x86_64-linux-gnu: read-only file system"}
Error syncing pod, skipping: failed to "StartContainer" for "Invoker" with rpc error: code = 2 desc = failed to start container "8d9125bf2d3711312a98a8b98de15306e495883cc470a03beb6689b34895791f": Error response from daemon: {"message":"mkdir /usr/lib/x86_64-linux-gnu: read-only file system"}: "Start Container Failed"
```

Then you might need to modify some of the volume mounts in the
[invoker.yml](invoker.yml). For example,
the error above is trying to find something from the apparmor mount which makes no
sense to CoreOS. To fix the issue, you just need to remove the mount.
