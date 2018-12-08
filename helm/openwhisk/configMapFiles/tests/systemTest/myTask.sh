# Licensed to the Apache Software Foundation (ASF) under one or more contributor
# license agreements; and to You under the Apache License, Version 2.0.

set -ex

# Clone openwhisk repo at specified tag to get test suite
git clone -q https://github.com/apache/incubator-openwhisk openwhisk
cd /openwhisk
git checkout $OW_GIT_TAG_OPENWHISK

# compile test suite
./gradlew --console=plain compileTestsScala

# run tests:testSystemBasic
./gradlew --console=plain :tests:testSystemBasic -Dwhisk.auth="$WSK_AUTH" -Dwhisk.server=$WSK_API_HOST_URL -Dopenwhisk.home=/openwhisk

echo "PASSED! Successfully executed tests:testSystemBasic"
