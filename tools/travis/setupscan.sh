#!/bin/bash
# Licensed to the Apache Software Foundation (ASF) under one or more contributor
# license agreements; and to You under the Apache License, Version 2.0.

SCRIPTDIR=$(cd $(dirname "$0") && pwd)
HOMEDIR="$SCRIPTDIR/../../../"

# clone OpenWhisk utilities repo. in order to run scanCode.py
cd $HOMEDIR
git clone https://github.com/apache/incubator-openwhisk-utilities.git
