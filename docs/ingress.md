<!--
#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
-->

Ingress
-------

Defining a Kubernetes Ingress is what makes the OpenWhisk system you
are going to deploy available outside of your Kubernetes cluster. When
you select an ingress method, you are determining what values to use
for the `whisk.ingress` stanza of your `mycluster.yaml` file that you
will use in the `helm install` command.  You will need to define
values for at least `whisk.ingress.type` and `whisk.ingress.api_host_name`
and `whisk.ingress.api_host_port`.

Unfortunately, the exact details of configuring an Ingress can vary
across cloud providers.  The detailed instructions describe multiple
possible Ingress configurations with specific details for some public
cloud providers.  We welcome contributions from the community to
describe how to configure Ingress for additional cloud providers.

If you are deploying on minikube, use the NodePort instructions below.

# NodePort

NodePort is the simplest type of Ingress and is suitable for use with
minikube and single node clusters that do not support more advanced
ingress options.  Deploying a NodePort ingress will expose a port on
each Kubernetes worker node for OpenWhisk's nginx service.

In this Ingress, TLS termination will be handled by OpenWhisk's
`nginx` service and will use self-signed certificates.  You will need
to invoke `wsk` with the `-i` command line argument to bypass
certificate checking.

## Setting up NodePort on minikube

First,  obtain the IP address of the single Kubernetes worker node.
```shell
minikube ip
```
This will return an ip address, for example `192.168.99.100`.

Next pick an unassigned port (eg 31001) and define `mycluster.yaml` as
```yaml
whisk:
  ingress:
    type: NodePort
    api_host_name: 192.168.99.100
    api_host_port: 31001

nginx:
  httpsNodePort: 31001
```

## Setting up NodePort on an IBM Cloud Lite cluster

The only available ingress method for an IBM Cloud Lite cluster is to
use a NodePort. Obtain the Public IP address of the sole worker node
by using the command
```shell
bx cs workers <my-cluster>
```
Then define `mycluster.yaml` as
```yaml
whisk:
  ingress:
    type: NodePort
    api_host_name: YOUR_WORKERS_PUBLIC_IP_ADDR
    api_host_port: 31001

nginx:
  httpsNodePort: 31001
```

# Standard

Many cloud providers will support creating a Kubernetes Ingress that
may offer additional capabilities features such as TLS termination,
load balancing, and other advanced features. We will call this a
`standard` ingress and provide a parameterized ingress.yaml as part of
the Helm chart that will create it using cloud-provider specific
parameters from your `mycluster.yaml`. Generically, your
`mycluster.yaml`'s ingress section will look something like:
```yaml
whisk:
  ingress:
    api_host_name: *<domain>*
    api_host_port: 443
    api_host_proto: https
    type: standard
    domain: *<domain>*
    tls:
      enabled: *<true or false>*
      secretenabled: *<true or false>*
      createsecret: *<true or false>*
      secretname: *<tlssecretname>*
      *<additional cloud-provider-specific key/value pairs>*
    annotations:
      *<optional list of cloud-provider-specific key/value pairs>*
```

Note that if you can setup an ingress that does not use self-signed
certificates for TLS termination you will be able to use `wsk` instead
of `wsk -i` for cli operations.

## IBM Cloud standard cluster

This cluster type does not use self-signed certificates for TLS
termination and can be configured with additional annotations to
fine tune ingress performance.

First, determine the values for <domain> and <ibmtlssecret> for
your cluster by running the command:
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
Ingress subdomain:  <domain>
Ingress secret:  <ibmtlssecret>
Workers:  3
```

Now define `mycluster.yaml` as below (substituting the real values for
`<domain>` and `<ibmtlssecret>`).
```yaml
whisk:
  ingress:
    api_host_name: <domain>
    api_host_port: 443
    api_host_proto: https
    type: standard
    domain: <domain>
    tls:
      enabled: true
      secretenabled: true
      createsecret: false
      secretname: <ibmtlssecret>
    annotations:
      # A blocking request is held open by the controller for slightly more than 60 seconds
      # before it is responded to with HTTP status code 202 (accepted) and closed.
      # Set to 75s to be on the safe side.
      # See https://console.bluemix.net/docs/containers/cs_annotations.html#proxy-connect-timeout
      # See http://nginx.org/en/docs/http/ngx_http_proxy_module.html#proxy_read_timeout
      ingress.bluemix.net/proxy-read-timeout: "75s"

      # Allow up to 50 MiB body size to support creation of large actions and large
      # parameter sizes.
      # See https://console.bluemix.net/docs/containers/cs_annotations.html#client-max-body-size
      # See http://nginx.org/en/docs/http/ngx_http_core_module.html#client_max_body_size
      ingress.bluemix.net/client-max-body-size: "size=50m"

      # Add the request_id, generated by nginx, to the request against the controllers. This id will be used as tid there.
      # https://console.bluemix.net/docs/containers/cs_annotations.html#proxy-add-headers
      ingress.bluemix.net/proxy-add-headers: |
        serviceName=controller {
          'X-Request-ID' $request_id;
        }

```

## Google Cloud with nginx ingress

This type of installation allows the same benefits as the IBM Cloud standard cluster.

According to your nginx ingress settings you can define a <domain> value of your choice. Check the official Google Cloud documentation here: https://cloud.google.com/kubernetes-engine/docs/tutorials/configuring-domain-name-static-ip. As stated you can create a domain of the type: `openwhisk.<your-chosen-dns-name>.com`

You can choose to create a tls secret for that <domain> and provide values for <tlscrt> and <tlskey> in base64.

To generate the values for <tlscrt> and <tlskey> you can use the openssl tool:

```
openssl req -newkey rsa:2048 -nodes -keyout tls.key -x509 -days 365 -out tls.crt
cat tls.key | base64
cat tls.crt | base64
```

Now define `mycluster.yaml` as below:

```yaml
whisk:
  ingress:
    api_host_name: <domain>
    api_host_port: 443
    api_host_proto: https
    type: standard
    domain: <domain>
    tls:
      enabled: true
      secretenabled: true
      createsecret: true
      secretname: openwhisk-ingress-tls-secret
      secrettype: kubernetes.io/tls
      crt: <tlscrt>
      key: <tlskey>
    annotations:
      kubernetes.io/ingress.class: nginx
      kubernetes.io/tls-acme: true
      nginx.ingress.kubernetes.io/proxy-body-size: 0
```

## Additional cloud providers

Please submit Pull Requests with instructions for configuing the
`standard` ingress for other cloud providers.
