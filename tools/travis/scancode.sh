#!/bin/bash
# Licensed to the Apache Software Foundation (ASF) under one or more contributor
# license agreements; and to You under the Apache License, Version 2.0.

set -e

# Build script for Travis-CI.
SCRIPTDIR=$(cd $(dirname "$0") && pwd)
ROOTDIR="$SCRIPTDIR/../.."
UTIL_DIR="$ROOTDIR/../incubator-openwhisk-utilities"

# run scancode
cd $UTIL_DIR
scancode/scanCode.py --config scancode/ASF-Release.cfg $ROOTDIR
