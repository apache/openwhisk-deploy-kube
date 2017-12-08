# Setting Up Minikube for OpenWhisk

First, download and install Minikube following these [instructions](https://github.com/kubernetes/minikube).

You will want at least 4GB of memory and 2 CPUs for Minikube to run OpenWhisk.
If you have a larger machine, you may want to provision more (especially more memory).

Start Minikube with:
```
minikube start --cpus 2 --memory 4096 --kubernetes-version v1.7.4
```

Put the docker network in promiscuous mode.
```
minikube ssh
(%) sudo ip link set docker0 promisc on
```

Your Minikube cluster should now be ready to deploy OpenWhisk.
