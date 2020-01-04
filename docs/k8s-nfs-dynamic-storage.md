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

You will need an already-provisioned NFS server supporting NFS v4 or better, preferably provisioned for at least 5 GB. The server must be set up to accept connections from all nodes in your cluster.

### Set up the nfs server

#### Helm chart
You may wish to consider the [nfs-server-provisioner](https://github.com/helm/charts/tree/master/stable/nfs-server-provisioner) Helm Chart to deploy a nfs server in your k8s cluster. If you experience any problems or you're just interested in setting up your own nfs server, try to set up manually with the following section.

#### Manually
Assuming you're using a linux machine, first install the nfs server related packages on the nfs server host.

On Ubuntu, use ``` sudo apt install nfs-kernel-server```.
On CentOS or Arch, install the ```nfs-utils``` package.

Now create a directory that you want to export to the server, which will be used in cluster. For example:
```
sudo mkdir /var/nfs/kubedata -p
```
We have to change the directory ownership to the nobody user, to match what nfs expects when we access the directory (note: for CentOS, it is **nfsnobody**).
```
sudo chown nobody: /var/nfs/kubedata
```

Then enable and start the nfs-server service:
```
sudo systemctl enable nfs-server.service
sudo systemctl start nfs-server.service
```

Now you have to "export" the nfs directory so that they can be accessed. At this point if you have a firewall enabled or you want to set one up, you need to open the NFS port. For example if you're using `firewalld`, you could open the SSH and NFS port:
```
firewall-cmd --permanent --zone=public --add-service=ssh
firewall-cmd --permanent --zone=public --add-service=nfs
firewall-cmd --reload
```

Open the `/etc/exports` file with a text editor and add the entry for your directory:
`/var/nfs/kubedata  *(rw,sync,no_subtree_check,no_root_squash,no_all_squash)`.

Here the chosen directory will be exported to the world using `*`, you can specify the nodes that can access the directory by using their IP: `/var/nfs/kubedata  <IP1>(options) ... <IPn>(options)`.

And run `sudo exportfs -rav` to make the changes effective.

The nfs server is now set up. You can check it by mounting the exported directory with a client node using `sudo mount -t nfs <Host IP>:/var/nfs/kubedata /mnt` (to unmount it after: `sudo umount /mnt`).

### Set up nfs client provisioner 

#### With the helm chart

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

#### Manually

TODO.