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

# Deploying OpenWhisk on OpenShift 4.6

## Overview

The 4.6 version of OpenShift is based on Kubernetes 1.19.

We assume you have an operational cluster that meets the
[technical requirements](openshift-technical-requirements.md) and that you
have sufficient privileges to perform the necessary `oc adm`
operations detailed below.

## Initial Setup

Create an openwhisk project (Kubernetes namespace) using the command
```shell
oc new-project openwhisk
```

Because OpenShift doesn’t allow pods to run with arbitrary UIDs
by default, you will need to add adjust some policy options
before deploying OpenWhisk.  Execute the following commands:
```shell
oc adm policy add-scc-to-user anyuid -z default
oc adm policy add-scc-to-user privileged -z default
oc adm policy add-scc-to-user anyuid -z openwhisk-core
oc adm policy add-scc-to-user privileged -z openwhisk-core
oc adm policy add-scc-to-user anyuid -z owdev-init-sa
oc adm policy add-scc-to-user privileged -z owdev-init-sa
```

## Configuring OpenWhisk

You must use the KubernetesContainerFactory on OpenShift.

### Red Hat OpenShift on IBM Cloud

A Red Hat OpenShift on IBM Cloud cluster has full support for TLS
including a wild-card certificate for subdomains and can be configured
with additional annotations to fine tune ingress performance.

First, determine the values for <domain> and <ibmtlssecret> for
your cluster by running the command:
```
ibmcloud cs cluster get -c <mycluster>
```
The CLI output will look something like
```
ibmcloud cs cluster get -c <mycluster>
Retrieving cluster <mycluster>...
OK
Name:    <mycluster>
...
Ingress Subdomain:  <domain>
Ingress Secret:     <ibmtlssecret>
...
```

The ingress secret is not automatically copied to new OpenShift
projects. Before deploying OpenWhisk, you will need to copy the
ingress secret (<ibmtlssecret> from the `openshift-ingress` namespace
to the `openwhisk` namespace.

As described in [IBM's ingress documentation](https://cloud.ibm.com/docs/containers/cs_ingress.html#ingress),
to enable applications deployed in multiple namespaces to share the ingress resource,
you should use a unique subdomain name for each namespace.  We suggest
a convention of using the namespace name as the subdomain name.  So if you
are deploying openwhisk into the `openwhisk` namespace, use `openwhisk`
as your subdomain (as shown below in the example `mycluster.yaml`).

A template [mycluster.yaml](../deploy/ibm-public/mycluster-roks.yaml]
for a standard deployment of OpenWhisk on ROKS would be:
```yaml
whisk:
  ingress:
    # NOTE: Replace <domain> with your cluster's actual domain
    apiHostName: openwhisk.<domain>
    apiHostPort: 443
    apiHostProto: https
    type: Standard
    useInternally: true
    # NOTE: Replace <domain> with your cluster's actual domain
    domain: openwhisk.<domain>
    tls:
      enabled: true
      secretenabled: true
      createsecret: false
      # NOTE: Replace <ibmtlssecret> with your cluster's actual tlssecret
      secretname: <ibmtlssecret>
    annotations:
      kubernetes.io/ingress.class: public-iks-k8s-nginx
      nginx.ingress.kubernetes.io/use-regex: "true"
      nginx.ingress.kubernetes.io/configuration-snippet: |
         proxy_set_header X-Request-ID $request_id;
      nginx.ingress.kubernetes.io/proxy-body-size: 50m
      nginx.ingress.kubernetes.io/proxy-read-timeout: "75"

k8s:
  dns: dns-default.openshift-dns

invoker:
  containerFactory:
    impl: kubernetes
``

## Limitations

No known limitations.
