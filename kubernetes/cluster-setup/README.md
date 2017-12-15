Cluster Setup
-------------

Before deploying the components of OpenWhisk to a Kubernetes cluster,
some initial configuration must be done to create a namespace,
configuration map, and other artifacts that are used by the
deployments and services that make up OpenWhisk.

Perform the following steps to prepare your cluster for OpenWhisk.

### Create the openwhisk namespace

```
kubectl apply -f namespace.yml
```

### Customize whisk.conf and create configmap

* Edit whisk.conf to match your deployment.
* Create a config map from it.
```
kubectl -n openwhisk create configmap whisk --from-env-file=whisk.env
```

### Create authorization secrets

The example commands below install the default guest and system
authorization credentials from the upstream open source project. In
production deployments, you should obviously use private credentials
to create these secrets.  The secrets auth.guest and auth.whisk.system
are used in some subsequent deployment steps to authorize pods to
perform actions. They must be defined or those steps will fail.

```
kubectl -n openwhisk create secret generic auth.guest --from-file=auth.guest
kubectl -n openwhisk create secret generic auth.whisk.system --from-file=auth.whisk.system
```
