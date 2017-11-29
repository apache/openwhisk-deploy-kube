Ingress
-------

To make your OpenWhisk deployment available outside of Kubernetes, you
need to configure an Ingress to expose the nginx service.
Unfortunately, the exact details of configuring an Ingress vary across
cloud providers.  The instructions below describe multiple possible
Ingress configurations.  We welcome contributions from the community
to describe how to configure ingress for all the major cloud provider
providers.

# NodePort

When it was deployed, the nginx service was configured to expose
itself via a NodePort [see](https://github.com/apache/incubator-openwhisk-deploy-kube/tree/master/kubernetes/nginx/nginx.yml#L10)
By determining the IP address of a worker node and the exposed port
number, you can determine your API_HOST. There are no additional files
to apply. TLS termination is handled by the nginx service.

 1. Obtain the IP address of the Kubernetes nodes.

 ```
 kubectl get nodes
 ```

 2. Obtain the public port for https port of the openwhisk.nginx Service

 ```
kubectl -n openwhisk describe service nginx | grep https-api | grep NodePort| awk '{print $3}' | cut -d'/' -f1
 ```

Use IP_ADDR:PUBLIC_PORT as your API_HOST


# Simple Service Ingress

A basic ingress that simply connects through to the nginx
service. With this ingress, TLS termination will be handled by the
OpenWhisk nginx service.

```
kubectl apply -f ingress-simple.yml
````

Use `kubectl get ingress` to determine the IP address and port to use
to define API_HOST for a simple service ingress.

# IBM Cloud

## IBM Cloud Lite cluster

The only available ingress method for a Lite cluster is to use a
NodePort (see above).  By determining the IP address of a worker node
and the exposed port number, you can determine your API_HOST. There
are no additional files to apply. TLS termination is handled by the
nginx service.

 1. Obtain the Public IP address of the sole worker node.

 ```
bx cs workers <my-cluster>
 ```

 2. Obtain the public port for https port of the openwhisk.nginx Service

 ```
kubectl -n openwhisk describe service nginx | grep https-api | grep NodePort| awk '{print $3}' | cut -d'/' -f1
 ```
Use PublicIP:PORT as your API_HOST

## IBM Cloud standard cluster

A template file ingress-ibm.yml is provided.  You will need to edit
this file to replace <ibmdomain> and <ibmtlssecret> with the correct
values for your cluster. Note that <ibmdomain> appears twice in the
template file.

To determine this values, run the command
```
bx cs cluster-get <mycluster>
```
The CLI output will look something like
```
bx cs cluster-get <mycluster>
Retrieving cluster <mycluster>...
OK
Name:    <mycluster>
ID:    b9c6b00dc0aa487f97123440b4895f2d
Created:  2017-04-26T19:47:08+0000
State:    normal
Master URL:  https://169.57.40.165:1931
Ingress subdomain:  <ibmdomain>
Ingress secret:  <ibmtlssecret>
Workers:  3
```
You can see the IBM-provided domain in the Ingress subdomain and the
IBM-provided certificate in the Ingress secret field.

After editing the template file, deploy it.
```
kubectl apply -f ingress-ibm.yml
```

Your OpenWhisk API_HOST will be <ibmdomain>/openwhisk


# Other cloud providers

Please submit Pull Requests with instructions for other cloud providers.
