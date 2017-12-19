#!/bin/bash

set -x

export OPENWHISK_HOME=/openwhisk

# Clone openwhisk repo to get latest installRouteMgmt.sh and core/routemgmt
# TODO: when OpenWhisk has releases, download release artifacts instead!
git clone https://github.com/apache/incubator-openwhisk openwhisk

cd $OPENWHISK_HOME

# Download and install openwhisk cli
pushd bin
  wget -q https://github.com/apache/incubator-openwhisk-cli/releases/download/$WHISK_CLI_VERSION/OpenWhisk_CLI-$WHISK_CLI_VERSION-linux-amd64.tgz
  tar xzf OpenWhisk_CLI-$WHISK_CLI_VERSION-linux-amd64.tgz
popd

# Setup env for installRouteMgmt.sh
if [ "$WHISK_API_GATEWAY_USER" ]; then
    export GW_USER=$WHISK_API_GATEWAY_USER
else
    export GW_USER=' '
fi
if [ "$WHISK_API_GATEWAY_PASSWORD" ]; then
    export GW_PWD=$WHISK_API_GATEWAY_PASSWORD
else
    export GW_PWD=' '
fi
if [ "$WHISK_API_GATEWAY_HOST_V2" ]; then
    export GW_HOST_V2=$WHISK_API_GATEWAY_HOST_V2
else
    echo "Must provide a value for WHISK_API_GATEWAY_HOST_V2"
    exit 1
fi

# Run installRouteMgmt.sh
pushd ansible/roles/routemgmt/files
  ./installRouteMgmt.sh $WHISK_AUTH $WHISK_API_HOST_NAME $WHISK_NAMESPACE $OPENWHISK_HOME/bin/wsk
popd

