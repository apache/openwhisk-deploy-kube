# Setting Up Minikube for OpenWhisk

First, download and install Minikube following these [instructions](https://github.com/kubernetes/minikube).

## Setup MacOS for local minikube
We recommend using the same versions we use in Travis, using asdf makes it very easy to select the version of minikube and kubectl

### Install asdf
```
brew install asdf
```
### Setup asdf in terminal
Edit your `~/.profile` or equivalent
```
[ -s "/usr/local/opt/asdf/asdf.sh" ] && . /usr/local/opt/asdf/asdf.sh
```

### Add minikune and kubectl plugins
```
asdf plugin-add kubectl
asdf plugin-add minikube
```

### Install asdf plugin minikube@0.23.0 and kubectl@1.7.4
```
asdf install kubectl 1.7.4
asdf global kubectl 1.7.4
asdf install minikube 0.23.0
asdf global minikube 0.23.0
```

## Create the minikube VM
You will want at least 4GB of memory and 2 CPUs for Minikube to run OpenWhisk.
If you have a larger machine, you may want to provision more (especially more memory).

Start Minikube with:
```
minikube start --cpus 2 --memory 4096 --kubernetes-version=v1.7.4
```

## Setup Docker network in promiscuous mode
Put the docker network in promiscuous mode.
```
minikube ssh -- sudo ip link set docker0 promisc on
```

Your Minikube cluster should now be ready to deploy OpenWhisk.
