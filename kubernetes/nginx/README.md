Nginx
-----

# Deploy Nginx

Depending on how you are deploying OpenWhisk, the Nginx pod
may or may not need to support handling TLS termination
for incoming requests. In production deployments, TLS termination
will be handled by an Ingress placed in front of the Nginx service.
In dev/test scenarios or when deploying on a single node cluster, it
is likely that you will use a basic Ingress that does not handle TLS
termination and therefore will need Nginx to handle it.

The instructions below configure Nginx with self-signed certificates
to enable basic TLS termination for dev/test.  If TLS termination is
being handled by the Ingress, you can optionally skip generating the
certificate, chop the ssl configuration and port 443 from nginx.conf,
and eliminate the secret from nginx.yml.  If you have real
certificates, you can modify nginx.conf with the proper hostname and
install them instead of the self-signed ones generated below.

## Generate self-signed certificates

* `certs.sh` can be used to generate self signed certs for OpenWhisk.
   By default, the current `nginx.conf` file expects the server url
   to use `localhost`. To generate a self signed cert with the same
   hostname for testing purposes just run:

   ```
   certs.sh localhost
   ```

   If you want to modify the domain name, make sure to update the
   [nginx.conf](nginx.conf) file appropriately.

## Create Nginx Secrets

With the generated certs for Nginx or your own certificates, you
should now be able to create the nginx Secrets. To create the Secrets
resource in the OpenWhisk namespace run the following command:

```
kubectl -n openwhisk create secret tls nginx --cert=certs/cert.pem --key=certs/key.pem
```

## Create Nginx ConfigMap

To create the ConfigMap in the OpenWhisk namespace with the `nginx.conf`
file, run the following command:

```
kubectl -n openwhisk create configmap nginx --from-file=nginx.conf
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

Kubernetes will then go through and update any deployed Nginx
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

