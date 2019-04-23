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

# Deploying OpenWhisk on Google GKE

## Overview

## Initial setup

### Creating the Kubernetes Cluster

Follow Google's instructions to provision your cluster.

### Configuring OpenWhisk

We recommend using an nginx ingress when running OpenWhisk on GKE.

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
    apiHostName: <domain>
    apiHostPort: 443
    apiHostProto: https
    type: Standard
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

## Hints and Tips


## Limitations

