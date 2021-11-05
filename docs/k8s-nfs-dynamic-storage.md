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
You may wish to consider the [nfs-server-provisioner](https://github.com/ckotzbauer/helm-charts/tree/main/charts/nfs-client-provisioner) Helm Chart to deploy a nfs server in your k8s cluster. If you experience any problems or you're just interested in setting up your own nfs server, try to set up manually with the following section.

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
Helm chart.

Create a local file `openwhisk-nfs-client-provisioner.yaml` to configure the
provisioner. You need to provide the server and path information. Note also
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

Using Helm 3, run this command to install it:
```
helm install your-ow-release-name --namespace openwhisk \
  stable/nfs-client-provisioner \
  -f ./openwhisk-nfs-client-provisioner.yaml
```

When you configure OpenWhisk, do remember to set
`k8s.persistence.hasDefaultStorageClass` to `false` and set
`k8s.persistence.explicitStorageClass` to be `openwhisk-nfs`.
And then you should be off to the races.

#### Manually

To manually deploy a nfs client provisioner, you have to create several things for your cluster.

- a Service Account
- a Role
- a Role Binding
- a Cluster Role
- a Cluster Role Binding
- a Storage Class
- a NFS Client Provisioner Deployment
- a Persistent Volume Claim

You could have a single yaml file, e.g. `rbac.yaml`, to take care of the first 5 items to create:
```yaml
kind: ServiceAccount
apiVersion: v1
metadata:
  name: nfs-client-provisioner
---
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: nfs-client-provisioner-runner
rules:
  - apiGroups: [""]
    resources: ["persistentvolumes"]
    verbs: ["get", "list", "watch", "create", "delete"]
  - apiGroups: [""]
    resources: ["persistentvolumeclaims"]
    verbs: ["get", "list", "watch", "update"]
  - apiGroups: ["storage.k8s.io"]
    resources: ["storageclasses"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["events"]
    verbs: ["create", "update", "patch"]
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: run-nfs-client-provisioner
subjects:
  - kind: ServiceAccount
    name: nfs-client-provisioner
    namespace: default
roleRef:
  kind: ClusterRole
  name: nfs-client-provisioner-runner
  apiGroup: rbac.authorization.k8s.io
---
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: leader-locking-nfs-client-provisioner
rules:
  - apiGroups: [""]
    resources: ["endpoints"]
    verbs: ["get", "list", "watch", "create", "update", "patch"]
---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: leader-locking-nfs-client-provisioner
subjects:
  - kind: ServiceAccount
    name: nfs-client-provisioner
    namespace: default
roleRef:
  kind: Role
  name: leader-locking-nfs-client-provisioner
  apiGroup: rbac.authorization.k8s.io
```

This creates a Service Account named `nfs-client-provisioner`, a Cluster Role with rules for persistent volumes, etc. (the same rules as the cluster role defined in the Helm chart) and a ClusterRoleBinding to bind the ClusterRole with the Service Account. The same for Role and Role Binding.

Apply it on your cluster with:
```
kubectl apply -f rbac.yaml
```
You can check the newly created roles with:
```
kubectl get clusterrole,clusterrolebinding,role,rolebinding | grep nfs

clusterrole.rbac.authorization.k8s.io/nfs-client-provisioner-runner                54s
clusterrolebinding.rbac.authorization.k8s.io/run-nfs-client-provisioner            54s
role.rbac.authorization.k8s.io/leader-locking-nfs-client-provisioner               54s
rolebinding.rbac.authorization.k8s.io/leader-locking-nfs-client-provisioner        54s
```

Now you have to create the Storage Class, in a file `sc.yaml`:
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: openwhisk-nfs
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: example/nfs
allowVolumeExpansion: true
parameters:
  archiveOnDelete: "false"
```

The name of the storage class is ```openwhisk-nfs```, when there is a persistent volume claim it must mention this storage class otherwise nothing will be provisioned. Apply the storage class:
```
kubectl apply -f sc.yaml
```
Check the result:
```
kubectl get storageclass
```

Now you are ready to deploy the actual nfs client provisioner. In a new yaml file, `deployment.yaml`:
```yaml
kind: Deployment
apiVersion: apps/v1
metadata:
  name: nfs-client-provisioner
spec:
  replicas: 1
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app: nfs-client-provisioner
  template:
    metadata:
      labels:
        app: nfs-client-provisioner
    spec:
      serviceAccountName: nfs-client-provisioner
      containers:
        - name: nfs-client-provisioner
          image: quay.io/external_storage/nfs-client-provisioner:latest
          volumeMounts:
            - name: nfs-client-root
              mountPath: /persistentvolumes
          env:
            - name: PROVISIONER_NAME
              value: example/nfs
            - name: NFS_SERVER
              value: <NFS-SERVER-HOST-IP>
            - name: NFS_PATH
              value: /var/nfs/kubedata
      volumes:
        - name: nfs-client-root
          nfs:
            server: <NFS-SERVER-HOST-IP>
            path: /var/nfs/kubedata
```

This will deploy a pod in the cluster that will take care about he dynamic provisioning with the nfs server. Change `<NFS-SERVER-HOST-IP>` with the proper IP where the nfs server is and in case you didn't use the `/var/nfs/kubedata` directory, change the value entry in *spec: containers: env* and *spec: volumes: nfs*.

Now you have a new pod in the cluster that takes care to handle the nfs server provisioning, but the cluster lacks a persistent volume claim configuration. So in a new file, `persistentvolumeclaim.yaml`:
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-nfs
spec:
  storageClassName: openwhisk-nfs
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 500Mi
```

Apply it with `kubectl apply -f persistentvolumeclaim.yaml`

You can check the results with `kubectl get pvc,pv -A`.
Now your cluster has Dynamic Provisioning enabled and you can deploy openwhisk.
