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
values for at least `whisk.ingress.type` and `whisk.ingress.api_host`.

Unfortunately, the exact details of configuring an Ingress vary across
cloud providers.  The detailed instructions
[below](#possible-ingress-types) describe multiple possible Ingress
configurations.  We welcome contributions from the community to
describe how to configure Ingress for additional cloud providers.

If you are deploying on minikube, use the NodePort instructions below.

# Possible Ingress Types

## NodePort

NodePort is the simplest type of Ingress and is suitable for use with
minikube and single node clusters that do not support more advanced
ingress options.  Deploying a NodePort ingress will expose a port on
each Kubernetes worker node for OpenWhisk's nginx service.
In this Ingress, TLS termination will be handled by OpenWhisk's
`nginx` service and will use self-signed certificates.  You will need
to invoke `wsk` with the `-i` command line argument to bypass
certificate checking.

First,  obtain the IP address of the Kubernetes nodes. If you are
using minikube, use the command
```shell
minikube ip
```
otherwise use
```
kubectl get nodes
```

Next pick an unassigned port (eg 31001) and define mycluster.yaml as
```yaml
whisk:
  ingress:
    type: NodePort
    api_host: 192.168.99.100:31001

nginx:
  httpsNodePort: 31001
```

## IBM Cloud

### IBM Cloud Lite cluster

The only available ingress method for a Lite cluster is to use a
NodePort (see above). Obtain the Public IP address of the sole worker
node by using the command
 ```
bx cs workers <my-cluster>
 ```
Then define mycluster.yaml as

```yaml
whisk:
  ingress:
    type: NodePort
    api_host: YOUR_WORKERS_PUBLIC_IP_ADDR:31001

nginx:
  httpsNodePort: 31001
```

### IBM Cloud standard cluster

This type of cluster can support a more advanced ingress style that
does not use self-signed certificates for TLS termination (you can use
`wsk` instead of `wsk -i`).  You will need to determine the values for
<ibmdomain> and <ibmtlssecret> for your cluster by running the command
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

Now define mycluster.yaml as below (substituting the real values for
`<ibmdomain>` and `<ibmtlssecret>`).
```yaml
whisk:
  ingress:
    type: ibm.standard
    ibmdomain: <ibmdomain>
    ibmtlssecret: <ibmtlssecret>
    api_host: <ibmdomain>
```

## Other cloud providers

Please submit Pull Requests with instructions for other cloud providers.
