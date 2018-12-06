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

# Using Dynamic Storage Provisioning for OpenWhisk

## NFS-based Dynamic Provisioning

You will need an already-provisioned NFS server supporting NFS v4 or better,
preferably provisioned for at least 5 GB.
The server must be set up to accept connections from all nodes in your cluster --
we leave it to you to determine the best strategy for that, though you may
wish to consider the
[nfs-server-provisioner](https://github.com/helm/charts/tree/master/stable/nfs-server-provisioner)
Helm Chart (*TODO: link*) if youhave lots of storage available on your nodes or
an NFS server provided by your cloud provider.

Once the NFS server is defined, the fastest way to make a dynamic file store
available is with the
[nfs-client-provisioner](https://github.com/helm/charts/tree/master/stable/nfs-client-provisioner)
helm Chart.

Create a local file `openwhisk-nfs-client-provisioner.yaml` to configure the
provisioner.  You need to provide the server and path information.  Note also
that the storageClass is explictly defined.

```yaml
nfs:
  #  See https://github.com/kubernetes-incubator/external-storage/tree/master/nfs-client
  server: <!-- To be provided -->
  path: <!-- To be provided -->

storageClass:
  name: openwhisk-nfs
  reclaimPolicy: Delete
```

And run a command to install it...
```
helm install --namespace openwhisk \
  --values ./openwhisk-nfs-client-provisioner.yaml \
  stable/nfs-client-provisioner
```

When you configure OpenWhisk, do remember to set
`k8s.persistence.hasDefaultStorageClass` to `false` and set
`k8s.persistence.explicitStorageClass` to be `openwhisk`.
And then you should be off to the races.
