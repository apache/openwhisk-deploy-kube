Cluster Setup
-------------

Before deploying the components of OpenWhisk to a Kubernetes cluster,
some initial configuration must be done to create a namespace
and authorization secrets that are used by the deployments and
services that make up OpenWhisk.

Perform the following steps to prepare your cluster for OpenWhisk.

### Create the openwhisk namespace

```
kubectl apply -f namespace.yml
```

### Create services

```
kubectl apply -f services.yml
```

### Configure system-wide version information and settings

Edit config.env as needed to set the appropriate values for your
deployment, then create the configmap whisk.config:

```
kubectl -n openwhisk create cm whisk.config --from-env-file=config.env
```

### Configure the set of supported runtimes

The file runtimes.json describes the supported action runtimes for
this installation of OpenWhisk.  The default file is identical to the
one found in the upstream ansible/files/runtime.json.  After making
any desired changes, install it in a configmap with

```
kubectl -n openwhisk create cm whisk.runtimes --from-file=runtimes=runtimes.json
```

### Configure limits for actions and triggers

Edit limits.env as needed to set the appropriate values for your
deployment, then create the configmap whisk.limits:

```
kubectl -n openwhisk create cm whisk.limits --from-env-file=limits.env
```

### Create authorization secrets

The command below installs the default guest and system authorization
credentials from the upstream open source project. In production
deployments, you should obviously use private credentials to create
these secrets.  The whisk.auth secret is used in subsequent deployment
steps to authorize pods to install actions and packages into the
deployed OpenWhisk. If it is not defined those steps will fail.

```
kubectl -n openwhisk create secret generic whisk.auth --from-file=system=auth.whisk.system --from-file=guest=auth.guest

```

### Create persistent volumes

Several of the OpenWhisk implementation components you will deploy in
subsequent steps require persistent storage to maintain their state
across crashes and restarts. The general mechanism in Kubernetes for
specifying storage needs and binding available storage to pods is
to match Persistent Volumes to Persistent Volume Claims.

The file persistent-volumes.yml file lists the PersistentVolume
resources you will need to create and defines them in a manner
appropriate for running OpenWhisk on minikube.  If you are not
deploying on minikube, you may need to edit this file to select
PersistentVolume types provided by your cloud provider. After
optionally editing the file, apply it with:

```
kubectl apply -f persistent-volumes.yml
```
