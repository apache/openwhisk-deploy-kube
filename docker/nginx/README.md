# Create Nginx Docker Image

We currently deploy a custom Nginx docker image that includes the
OpenWhisk CLI and other downloadable artifacts. Once there are proper
releases of these artifacts, we can switch to using a standard Nginx
image and redirect to the official release archives for the artifacts
we are currently storing in the custom docker image.  See the GitHub
[issue](https://github.com/openwhisk/openwhisk/issues/2152).

To build the Nginx docker image for Kubernetes on OpenWhisk,
you will need to run the build script [build.sh](docker/build.sh).
This script requires one parameter, which is the repo to bush
the Docker image to.

E.G
```
docker/builds.sh <danlavine>
```

This script goes through and donwload the OpenWhisk repo under the
tmp directory, builds the Blackbox image and copies it into the
Docker image.  Then, each of the published WSK CLIs are download into
the Docker image so that users are able to download them as usual.

