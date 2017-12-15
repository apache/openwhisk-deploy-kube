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

# Generate whisk.properties.
# TODO: Refactor upstream ansible/roles/routemgmt/files/installRouteMgmt.sh to enable
# override of apigw values from environment so we don't have to bother running
# ansible here to generate whisk.properties just so the script can extract 3 values.
pushd ansible
  ansible-playbook setup.yml
  ansible-playbook properties.yml -e apigw_host_v2=$WHISK_API_GATEWAY_HOST_V2
popd

# Run installRouteMgmt.sh
pushd ansible/roles/routemgmt/files
  ./installRouteMgmt.sh $WHISK_AUTH $WHISK_API_HOST_NAME $WHISK_NAMESPACE $OPENWHISK_HOME/bin/wsk
popd

