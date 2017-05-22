# This script assumes Docker is already installed
#!/bin/bash

TAG=v1.5.5

# set docker0 to promiscuous mode
sudo ip link set docker0 promisc on

# install etcd
wget https://github.com/coreos/etcd/releases/download/v3.0.14/etcd-v3.0.14-linux-amd64.tar.gz
tar xzf etcd-v3.0.14-linux-amd64.tar.gz
sudo mv etcd-v3.0.14-linux-amd64/etcd /usr/local/bin/etcd
rm etcd-v3.0.14-linux-amd64.tar.gz
rm -rf etcd-v3.0.14-linux-amd64

# download kubectl
wget https://storage.googleapis.com/kubernetes-release/release/$TAG/bin/linux/amd64/kubectl
chmod +x kubectl
sudo mv kubectl /usr/local/bin/kubectl

# download kubernetes
git clone https://github.com/kubernetes/kubernetes $HOME/kubernetes

pushd $HOME/kubernetes
  git checkout $TAG
  kubectl config set-credentials myself --username=admin --password=admin
  kubectl config set-context local --cluster=local --user=myself
  kubectl config set-cluster local --server=http://localhost:8080
  kubectl config use-context local

  # start kubernetes in the background
  sudo PATH=$PATH:/home/travis/.gimme/versions/go1.7.linux.amd64/bin/go \
       KUBE_ENABLE_CLUSTER_DNS=true \
       hack/local-up-cluster.sh &
popd

# Wait untill kube is up and running
TIMEOUT=0
TIMEOUT_COUNT=30
until $( curl --output /dev/null --silent http://localhost:8080 ) || [ $TIMEOUT -eq $TIMEOUT_COUNT ]; do
  echo "Kube is not up yet"
  let TIMEOUT=TIMEOUT+1
  sleep 20
done

if [ $TIMEOUT -eq $TIMEOUT_COUNT ]; then
  echo "Kubernetes is not up and running"
  exit 1
fi

echo "Kubernetes is deployed and reachable"

sudo chown -R $USER:$USER $HOME/.kube
