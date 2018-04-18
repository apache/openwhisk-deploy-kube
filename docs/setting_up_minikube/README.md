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

### Install asdf plugin minikube and kubectl
For example this will setup versions 1.10.1 and 0.26.0, check the versions that are supported in the Travis matric config [../.travis.yml](../.travis.yml#L7)
```
asdf install minikube 0.26.0
asdf global minikube 0.26.0
asdf install kubectl 1.10.1
asdf global kubectl 1.10.1
```

## Create the minikube VM
You will want at least 4GB of memory and 2 CPUs for Minikube to run OpenWhisk.
If you have a larger machine, you may want to provision more (especially more memory).

Configure minikube and persiste config:
```
minikube config set kubernetes-version v1.10.1
minikube config set cpus 2
minikube config set memory 4096
```

Then start minikube VM:
```
minikube start
```

## Setup Docker network in promiscuous mode
Put the docker network in promiscuous mode.
```
minikube ssh -- sudo ip link set docker0 promisc on
```

**Tip**: Make sure to setup the Docker network after `minkube start` if you ran `minkube delete` as this configuration will be lost.

Your Minikube cluster should now be ready to deploy OpenWhisk.

Delete minkube VM:
This is useful if you plan to test with a different combination of minkube and kubernetes versions.
```
minikube delete
```

# Troubleshooting

For some combinations of Minikube and Kubernetes versions, you may need to workaround a [Minikube DNS issue](https://github.com/kubernetes/minikube/issues/2240#issuecomment-348319371). A common symptom of this issue is that the OpenWhisk couchdb pod will fail to start with the error that it is unable to resolve `github.com` when cloning the openwhisk git repo. A work around is to delete the minikube cluster, issue the command `minikube config set bootstrapper kubeadm` and then redo the `minikube start` command above.
