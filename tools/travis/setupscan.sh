#!/bin/bash

SCRIPTDIR=$(cd $(dirname "$0") && pwd)
HOMEDIR="$SCRIPTDIR/../../../"

# clone OpenWhisk utilities repo. in order to run scanCode.py
cd $HOMEDIR
git clone https://github.com/apache/incubator-openwhisk-utilities.git
