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

# Deploying OpenWhisk on "build-it-yourself" Kubernetes clusters

## Overview

This document is an attempt to summarize configuration choices to make
when deploying OpenWhisk on a Kubernetes cluster you have built
yourself (ie, not on a public cloud managed Kubernetes service).

First, make sure your cluster is compatible with the
[technical requirements](k8s-technical-requirements.md).

### Configuring OpenWhisk

#### NodePort Ingress

The simplest type of ingress to configure for OpenWhisk is a NodePort ingress.

Add the following to your `mycluster.yaml`, substituting a real IP address
for YOUR_WORKERS_PUBLIC_IP_ADDR:
```yaml
whisk:
  ingress:
    type: NodePort
    apiHostName: YOUR_WORKERS_PUBLIC_IP_ADDR
    apiHostPort: 31001

nginx:
  httpsNodePort: 31001
```

### Using an ingress controller

Properly configuring TLS can be challenging, but if you know how to get TLS
to work with your ingress controller for other services on your cluster,
you can probably get it to work for OpenWhisk as well.
You will need something like the following in your `mycluster.yaml`.
```yaml
whisk:
  ingress:
    apiHostName: <domain>
    apiHostPort: 443
    apiHostProto: https
    type: Standard
    domain: <domain>
    tls:
      enabled: true
      <YOU WILL NEED SOME MORE KEY VALUE PAIRS HERE>
    annotations:
      <LIST ANNOTATIONS YOU NEED FOR YOUR INGRESS>
```
You can see how these values are used and what other values you might
need by inspecting
[frontdoor-ingress.yaml](../helm/openwhisk/templates/frontdoor-ingress.yaml)
and
[frontdoor-secrets.yaml](../helm/openwhisk/templates/frontdoor-secrets.yaml).


