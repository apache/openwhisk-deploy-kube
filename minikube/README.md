# Deploying OpenWhisk to Minikube

**Note:** this is currently experimental, and the integration tests
don't yet run against Minikube on CI. Minikube currently uses an old
version of Docker (v1.11.x), so may not be fully compatible with
OpenWhisk (see [Requirements](../README.md#requirements) for more
info). These steps have only been manually tested with Minikube
v0.19.1.


# Installation

1. Download and set up [Minikube](https://github.com/kubernetes/minikube)
2. Start minikube with `minikube start`
3. run `./deploy_minikube.sh`. This will configure Minikube for
   OpenWhisk, run the standard Kubernetes OpenWhisk deployment, then
   reconfigure the Invoker so it can properly talk to the Docker
   daemon used by Minikube

Once you've started the deploy script, you can follow along on the
progress of the configuration task as noted in the
[top-level README](../README.md#configure-openwhisk). 


# The details

There are currently two changes required in order for OpenWhisk to
work on Minikube, both of which are performed by the deploy script:

1. The `docker0` interface inside Minikube needs to be put into
   promiscuous mode to allow Kafka to talk to ZooKeeper
2. The Docker client used by the Invoker is newer than the Docker
   daemon provided by Minikube, so we have to set an environment
   variable (`DOCKER_API_VERSION`) in the environment for the
   Invoker's container (via the StatefulSet template) to force it to
   use an older version of the API protocol (1.23). We then need to
   delete the existing Invoker pod that was started by the initial
   deploy to force a new one to be created with the new environment.



