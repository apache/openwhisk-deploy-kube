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

# Deploying OpenWhisk on Amazon EKS

## Overview

## Initial setup

### Creating the Kubernetes Cluster

Follow Amazon's instructions to provision your cluster.

### Configuring OpenWhisk using SSL and IAM

AWS's Elastic Kubernetes Service (EKS) does not support standard Kubernetes
ingress.  Instead, it relies on provisioning Elastic Load
Balancers (ELBs) outside of the EKS cluster to direct traffic to
exposed services running in the cluster.  Because the `wsk` cli
expects to be able to use TLS to communicate securely with the OpenWhisk
server, you will first need to ensure that you have a certificate
available for your ELB instance to use in AWS's IAM service. For
development and testing purposes, you can use a self-signed
certificate (for example the `openwhisk-server-cert.pem` and
`openwhisk-server-key.pem` that are generated when you build OpenWhisk
from source and can be found in the
`$OPENWHISK_HOME/ansible/roles/nginx/files` directory. Upload these to
IAM using the aws cli:
```shell
aws iam upload-server-certificate --server-certificate-name ow-self-signed --certificate-body file://openwhisk-server-cert.pem --private-key file://openwhisk-server-key.pem
```
Verify that the upload was successful by using the command:
```shell
aws iam list-server-certificates
```
A typical output would be as shown below
```
{
    "ServerCertificateMetadataList": [
        {
            "ServerCertificateId": "ASCAJ4HPCCVA65ZHD5TFQ",
            "ServerCertificateName": "ow-self-signed",
            "Expiration": "2019-10-01T20:50:02Z",
            "Path": "/",
            "Arn": "arn:aws:iam::12345678901:server-certificate/ow-self-signed",
            "UploadDate": "2018-10-01T21:27:47Z"
        }
    ]
}
```

Add the following to your `mycluster.yaml`, using your certificate's Arn
instead of the example one:

```yaml
whisk:
  ingress:
    type: LoadBalancer
    annotations:
      service.beta.kubernetes.io/aws-load-balancer-internal: 0.0.0.0/0
      service.beta.kubernetes.io/aws-load-balancer-ssl-cert: arn:aws:iam::12345678901:server-certificate/ow-self-signed
```

Shortly after you deploy your helm chart, an ELB should be
automatically created. You can determine its hostname by issuing
the command `kubectl get services -o wide`. Use the value in the
the EXTERNAL-IP column for the nginx service and port 443 to define
your wsk apihost.

NOTE: It may take several minutes after the ELB is reported as being
available before the hostname is actually properly registered in DNS.
Be patient and keep trying until you stop getting `no such host`
errors from `wsk` when attempting to access it.

### Configuring Openwhisk using SSL and Elastic Loadbalancers

Due to the way AWS supports TLS termination on ELBs there are a couple of configuration options required to put a
signed certificate in place when deploying openwhisk.

First ensure you have a signed certificate in your AWS Certificate Manager.

Then ensure you enable the following:
```yaml
whisk:
  ingress:
    awsSSL: "true"
    type: LoadBalancer
    annotations:
      service.beta.kubernetes.io/aws-load-balancer-backend-protocol: http
      service.beta.kubernetes.io/aws-load-balancer-ssl-ports: https-api
      service.beta.kubernetes.io/aws-load-balancer-ssl-cert: <your certificate ARN>
```

This will setup a loadbalanced service that allows your users to connect via HTTPS to the cluster. Internally we switch
from SSL to plain HTTP communication as we're forwarding ports internally.
Please read [this doc](https://kubernetes-on-aws.readthedocs.io/en/latest/user-guide/tls-termination.html#common-pitfalls) for more information.

## Hints and Tips

## Limitations

If you used a self-signed certificate, you will need to invoke `wsk`
with the `-i` command line argument to bypass certificate checking.
