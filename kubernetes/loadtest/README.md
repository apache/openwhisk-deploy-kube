<!--
#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
-->

LoadTest
-----

A collection of jobs to do performance testing
against openwhisk deployed on kube, based on
the code in apache/incubator-openwhisk-performance.git.

The jobs are intended to run in the openwhisk namespace in the same
cluster as the system under test to eliminate external network
latency.

# Preparing

The Jobs assume the noopLatency and noopThroughput actions are already
created in the default namespace.  These actions are simple noops
(for example a JavaScript action whose body is `function main(){return {};}`).

# Runnning

To run one of the Jobs, edit the yml to adjust test parameters and then

```
kubectl apply -f loadtest-latency.yml
```
