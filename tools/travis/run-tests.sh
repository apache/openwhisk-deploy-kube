#!/bin/bash
# Licensed to the Apache Software Foundation (ASF) under one or more contributor
# license agreements; and to You under the Apache License, Version 2.0.

###
# Now run the tests provided in the Chart to verify the deployment
###
if helm test ow4travis --timeout 1200; then
    echo "PASSED! Deployment verification tests passed."
else
    echo "FAILED: Deployment verification tests failed."
    kubectl logs -n openwhisk -low-testpod=true
    exit 1
fi
