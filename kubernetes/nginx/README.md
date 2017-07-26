Nginx
-----

# Deploy Nginx

The Nginx Pod needs to be configured with custom certificates
and nginx configuration file. To achieve this, nginx will need
to create a Kube ConfigMap for the `nginx.conf` file and a
Secrets resource with the certs.

To help generate the certs there is a little helper script.

* `certs.sh` can be used to generate self signed certs for OpenWhisk.
   By default, the current `nginx.conf` file expects the server url
   to use `localhost`. To generate a self signed cert with the same
   hostname for testing purposes just run:

   ```
   certs.sh localhost
   ```

   If you want to modify the domain name, make sure to update the
   [nginx.conf](nginx.conf) file appropriately.

## Create Nginx ConfigMap

To create the ConfigMap in the OpenWhisk namespace with the `nginx.conf`
file, run the following command:

```
kubectl -n openwhisk create configmap nginx --from-file=nginx.conf
```

## Create Nginx Secrets

With the generated certs for Nginx, you should now be able to create
the nginx Secrets. To create the Secrets resource in the OpenWhisk
namespace run the following command:

```
kubectl -n openwhisk create secret tls nginx --cert=certs/cert.pem --key=certs/key.pem
```

## Deploying Nginx

After successfully [creating the nginx ConfigMap](#create-nginx-configmap)
and [creating the Secrets](#create-nginx-secrets)
you will be able to create the Nginx Service and Deployment.

```
kubectl apply -f nginx.yml
```

# Deployment Changes
## Update Nginx ConfigMap

To update the nginx ConfigMap:

```
kubectl -n openwhisk edit cm nginx -o yaml
```

Kubernetes will then go through an update any deployed Nginx
instances. Updating all of the keys defined in the nginx
ConfigMap.

## Update Nginx Secrets

When updating the nginx Secrets, you will need to have the
actual yaml file. To obtain the generated YAML file run:

```
kubectl -n openwhisk get secrets nginx -o yaml > nginx_secrets.yml
```

Then you can manually edit the fields by hand. Remember that the
values in a secrets file are base64 encoded values. Also, you
will need to remove a couple of fields from the `metadata` section.

```
  creationTimestamp: 2017-06-21T15:39:56Z
  resourceVersion: "2156"
  selfLink: /api/v1/namespaces/openwhisk/configmaps/nginx
  uid: e0585576-5697-11e7-aef9-080027a9c6c9
```

When you have finished editing the yaml file, run:

```
kubectl replace -f nginx_secrets.yml
```

Kubernetes will then go through an update any deployed Nginx
instances. Updating all of the keys defined in the nginx
Secrets.

## Increase Controller Count

If you are updating the number of controllers being deployed with OpenWhiks
from the default 2, you will need to make a few changes. The Nginx conf
file has routes for Controller [StatefulSet][StatefulSet] addresses.
Specifically [these lines](https://github.com/apache/incubator-openwhisk-deploy-kube/tree/master/kubernetes/nginx/nginx.conf#L15-L20).
will need to be updated with a list of all available routes.

[StatefulSet]: https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/
