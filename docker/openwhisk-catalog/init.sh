#!/bin/bash

set -x

# Clone openwhisk-catalog
# TODO: when openwhisk-catalog has releases, download release instead!
git clone https://github.com/apache/incubator-openwhisk-catalog openwhisk-catalog

# TODO: installCatalog.sh wants OPENWHISK_HOME set, but doesn't actually need
# it for anything.  Fix upstream and then remove this.
export OPENWHISK_HOME=/openwhisk
mkdir -p $OPENWHISK_HOME/bin

# Download and install openwhisk cli
pushd $OPENWHISK_HOME/bin
  wget -q https://github.com/apache/incubator-openwhisk-cli/releases/download/$WHISK_CLI_VERSION/OpenWhisk_CLI-$WHISK_CLI_VERSION-linux-amd64.tgz
  tar xzf OpenWhisk_CLI-$WHISK_CLI_VERSION-linux-amd64.tgz
popd

# Run installCatalog.sh
pushd openwhisk-catalog/packages
  ./installCatalog.sh $WHISK_AUTH $WHISK_API_HOST_NAME $OPENWHISK_HOME/bin/wsk
popd

