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

# Technical Requirements for OpenShift

The OpenShift cluster on which you are deploying OpenWhisk must meet
the following requirements:
* OpenShift version 4.5 or newer (these instructions were tested on 4.5).
* The ability to create Ingresses to make a Kubernetes service
  available outside of the cluster so you can actually use OpenWhisk.
* Unless you disable persistence (see
  [configurationChoices.md](configurationChoices.md)),
  either your cluster must be configured to support [Dynamic Volume
  Provision](https://kubernetes.io/docs/concepts/storage/dynamic-provisioning/)
  and you must have a DefaultStorageClass admission controller enabled
  or you must manually create any necessary PersistentVolumes when
  deploying the Helm chart.
