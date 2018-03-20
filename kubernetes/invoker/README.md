Invoker
-------

# Overview

The Invoker is responsible for creating and managing the containers
that OpenWhisk creates to execute the user defined functions.  A key
function of the Invoker is to manage a cache of available warm
containers to minimize cold starts of user functions.
Architecturally, we support two options for deploying the Invoker
component on Kubernetes (selected by picking a
`ContainerFactoryProviderSPI` for your deployment).
  1. `DockerContainerFactory` matches the architecture used by the
      non-Kubernetes deployments of OpenWhisk.  In this approach, an
      Invoker instance runs on every Kubernetes worker node that is
      being used to execute user functions.  The Invoker directly
      communicates with the docker daemon running on the worker node
      to create and manage the user function containers.  The primary
      advantages of this configuration are lower latency on container
      management operations and robustness of the code paths being
      used (since they are the same as in the default system).  The
      primary disadvantage is that it does not leverage Kubernetes to
      simplify resource management, security configuration, etc. for
      user containers.
  2. `KubernetesContainerFactory` is a truly Kubernetes-native design
      where although the Invoker is still responsible for managing the
      cache of available user containers, the Invoker relies on Kubernetes to
      create, schedule, and manage the Pods that contain the user function
      containers. The pros and cons of this design are roughly the
      inverse of `DockerContainerFactory`.  Kubernetes pod management
      operations have higher latency and exercise newer code paths in
      the Invoker.  However, this design fully leverages Kubernetes to
      manage the execution resources for user functions.

# Deploying

## Label the worker nodes

In either approach, it is desirable to indicate which worker nodes
should be used to execute user containers.  Do this by labeling each
node with `openwhisk-role=invoker`.  For a single node cluster, simply do
```
kubectl label nodes --all openwhisk-role=invoker
```
If you have a multi-node cluster, for each node <INVOKER_NODE_NAME>
you want to be an invoker, execute
```
$ kubectl label nodes <INVOKER_NODE_NAME> openwhisk-role=invoker
```

## Deploying using the DockerContainerFactory

### Create the invoker.config config map

Edit invoker-dcf.env to make any customizations needed for your
deployment, create the config map:
```
kubectl -n openwhisk create cm invoker.config --from-env-file=invoker-dcf.env
```

### Deploy the Invoker as a DaemonSet

This will deploy an Invoker instance on every Kubernetes worker node
labeled with openwhisk-role=invoker.
```
kubectl apply -f invoker-dcf.yml
```

## Deploying using the KubernetesContainerFactory

The KubernetesContainerFactory can be deployed with an additional
invokerAgent that implements container suspend/resume operations on
behalf of a remote Invoker.  The instructions here included deploying
the invokerAgent.  If you do not want to do this, skip deploying the
invokerAgent daemonset and edit invoker-k8scf.yml to set
`CONFIG_whisk_kubernetes_invokerAgent_enabled` to `FALSE`.

### Create the invoker.config config map

Edit invoker-k8scf.env to make any customizations needed for your
deployment, create the config map:
```
kubectl -n openwhisk create cm invoker.config --from-env-file=invoker-k8scf.env
```

### Deploy the invokerAgent Daemonset
```
kubectl apply -f invoker-agent.yml
```
Wait for all of the invoker-agent pods to be running.  This might take a
couple of minutes because the invoker-agent also prefetches the docker images
for the default set of user action runtimes by doing docker pulls as an
init container.

### Deploy the Invoker as a StatefulSet

By default, this will deploy a single Invoker instance.  Optionally
edit invoker-k8scf.yml to change the number of Invoker replicas and
then do:
```
kubectl apply -f invoker-k8scf.yml
```


# Troubleshooting
## No invokers are deployed with DockerContainerFactory

Verify that you actually have at least one node with the label openwhisk-role=invoker.

## Invokers containers fail to start with volume mounting problems

To execute the containers for user actions, OpenWhisk relies on part
of the underlying infrastructure that Kubernetes is running on. When
deploying the Invoker for OpenWhisk, it mounts the host's Docker
socket and several other system-specific directories related to
Docker. This enables efficient container management, but it also also
means that the default volume hostPath values assume that the Kubernetes worker
node image is Ubuntu. If containers fail to start with errors related
mounting`/sys/fs/cgroup`, `/run/runc`,`/var/lib/docker/containers`, or
`/var/run/docker.sock`, then you will need to change the corresponding
value in [invoker-dcf.yml](invoker-dcf.yml) to match the host operating system
running on your Kubernetes worker node.
