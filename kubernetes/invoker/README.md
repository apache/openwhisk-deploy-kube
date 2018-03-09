Invoker
-------

# Deploying

## Create config map

Edit invoker.env as needed to set the appropriate values for your
deployment, then create the configmap invoker.config:

```
kubectl -n openwhisk create cm invoker.config --from-env-file=invoker.env
```

## Deploy Invoker

When deploying the Invoker, it needs to be deployed via a
[DaemonSet](https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/).
This is because there should only ever be at most 1 Invoker
instance per Kube Node. To set these restrictions, it will be
up to the Kubernetes deployment operator to properly apply
the correct labels and taints to each required Kube node.

With the defaults in the current `invoker.yml`, you can setup a
node to run only Invoker pods with:

```
kubectl label nodes [node name] openwhisk-role=invoker
$ kubectl label nodes 127.0.0.1 openwhisk-role=invoker
```

Once the invoker label is applied, you can create the invokers with:

```
kubectl apply -f invoker.yml
```

**Important**


# Troubleshooting
## No invokers are deployed

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
value in [invoker.yml](invoker.yml) to match the host operating system
running on your Kubernetes worker node.
