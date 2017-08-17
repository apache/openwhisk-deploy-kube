#!/bin/bash
set -e

# Build script for Travis-CI.
SCRIPTDIR=$(cd $(dirname "$0") && pwd)
ROOTDIR="$SCRIPTDIR/../.."
UTIL_DIR="$ROOTDIR/../incubator-openwhisk-utilities"

# run scancode
cd $UTIL_DIR
scancode/scanCode.py $ROOTDIR
