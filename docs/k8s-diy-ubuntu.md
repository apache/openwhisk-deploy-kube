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

# Kubernetes cluster example with Ubuntu

You can easily build a cluster using kubeadm and kubectl on Ubuntu 18.04.

### Perform these steps on **all the machines** that will be part of your cluster.

First, have Docker installed:
```
sudo apt-get install -y docker.io
```

Then install the kubeadm toolbox:
```
sudo apt-get update && sudo apt-get install -y apt-transport-https curl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
```

Swap must be disabled for kubelet to run:
```
sudo swapoff -a
```

### Only on the machine designated as **master node**:

Select the IP address to broadcast the Kubernetes API. With ``` ifconfig ``` you can check the IPs of the network interfaces on your master node (with a public IP you can expose the cluster to the internet).

Then run the following line substituting ```<IP-address>``` with your IP.
```
sudo kubeadm init --apiserver-advertise-address=<IP-address>
```
When it finishes executing, you will find a result similar to this:
```
Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join <IP-address>:6443 --token 29am26.3fw2znktwbbff0we \
    --discovery-token-ca-cert-hash sha256:eb32f7f58ae6907f26ed5c075ecd4ef6756d832b6c358fd4b2f408e52d18a369
```
Now kubeadm set up a cluster with just the master node. Run those 3 instructions to copy the admin.conf file, to connect kubectl to the new cluster.

Then you can checkout your nodes with:
```
kubectl get nodes

NAME          STATUS     ROLES    AGE     VERSION
master-node   NotReady   master   7m25s   v1.17.0
```
The node will stay in the **NotReady** status until you apply Pod Networking. With Weave Net run:
```
kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"
```
After a minute the node will be **Ready**. Check the [Weave Net addon](https://www.weave.works/docs/net/latest/kubernetes/kube-addon/#install) to know more.

Now you're ready to let other machines join. Use the join command kubeadm printed earlier on them.
```
kubeadm join <IP-address>:6443 --token 29am26.3fw2znktwbbff0we \
    --discovery-token-ca-cert-hash sha256:eb32f7f58ae6907f26ed5c075ecd4ef6756d832b6c358fd4b2f408e52d18a369

```
After a node joined give it time to get in the Ready status, then you can check that everything is
running with: ```kubectl get all -A```.

Now you have a running cluster with a master node and one or more worker nodes.

Before deploying OpenWhisk, you have to set up [Dynamic Volume
Provision](https://kubernetes.io/docs/concepts/storage/dynamic-provisioning/), as the [technical
requirements](k8s-technical-requirements.md) specify. For example, you can dynamically provision NFS persistent volumes, setting up an nfs server, a client provisioner and a storage class. Now you're ready to deploy openwhisk with [Helm](../README.md#deploy-with-helm).

#### Weave Network Plugin Troubleshooting
ensure that weave has launched by running `kubectl get pods -A` and looking for a pod named similarly to `weave-net-#####` - if the status is `Running` you're good. if you see `CrashLoopBackOff` perform the following steps:
1. Get logs `kubectl logs -n kube-system weave-net-m4j75 -c weave`
2. if you see an error like this: `Network 10.32.0.0/12 overlaps with existing route 10.33.82.0/23 on host` that means you need to choose a different network for kubernetes to assign to itself
3. return your cluster to a default state `sudo kubeadm reset` and hit y when it asks if you're certain you want to do this
4. Choose a new [private network](https://en.wikipedia.org/wiki/Private_network) and init the cluster like this: `sudo kubeadm init --pod-network-cidr=192.168.128.0/17 --apiserver-advertise-address=<IP ADDRESS>`
5. tell the weave plugin to use these new values as listed in the [configuration options](https://www.weave.works/docs/net/latest/kubernetes/kube-addon/#-changing-configuration-options) `kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')&env.IPALLOC_RANGE=192.168.128.0/17"`
6. it should now show as `Running` under status

