This directory contains the Dockerfiles and other artifacts to
build specialized docker images for deploying OpenWhisk to Kubernetes.

These images are built automatically and published
to DockerHub under the openwhisk userid.  Docker images are
published on all successful Travis CI builds of the master branch.
The built images are:
  * couchdb - creates and initializes a CouchDB instance for
    dev/testing of OpenWhisk.  This image is not intended for
    production usage.
  * routemgmt - installs OpenWhisk's route management package
    in the system namespace of the OpenWhisk deployment.
  * openwhisk-catalog - installs the catalog from the project
    incubator-openwhisk-calalog to the system namespace of the
    OpenWhisk deployment.
