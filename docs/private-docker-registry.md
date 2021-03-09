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

# Using private docker registry

By default, helm charts currently use docker hub to download images to deploy OpenWhisk components on Kubernetes. If your Kubernetes provider does not allow public docker registry, you can use your hosted docker image registry to deploy OpenWhisk on Kubernetes.

- All openwhisk images should be uploaded to your hosted docker registry server.
  - openwhisk/apigateway
  - apache/couchdb
  - openwhisk/controller
  - openwhisk/invoker
  - wurstmeister/kafka
  - openwhisk/ow-utils
  - zookeeper
  - nginx
  - redis
  - busybox
  - openwhisk/alarmprovider
  - openwhisk/kafkaprovider

- Add details of your docker registry information in mycluster.yml.

  ```yaml
  docker:
    registry:
      name: "registry-name/"
      username: username
      password: "Password"
  ```

  > - enabling registry information will cause all your images to be pulled from private docker registry only.
  > - Append / in your docker registry name.

Enabling *registry.name* will create a docker-registry secret as *{ReleaseName}-private-registry.auth* in Kubernetes which will be used in pod/jobs as *imagePullSecrets*.

```yaml
# If ReleaseName is owdev and namespace is openwhisk
# kubectl get secrets owdev-private-registry.auth -o yaml

apiVersion: v1
data:
  .dockerconfigjson: <Base64 encoded>
kind: Secret
metadata:
  annotations:
    kubectl.kubernetes.io/last-applied-configuration: |
      {"apiVersion":"v1","data":{".dockerconfigjson":"Base64 Encoded"},"kind":"Secret","metadata":{"annotations":{},"labels":{"app":"owdev-openwhisk","chart":"openwhisk-0.1.4","heritage":"Tiller","release":"owdev"},"name":"owdev-private-registry.auth","namespace":"openwhisk"},"type":"kubernetes.io/dockerconfigjson"}
  creationTimestamp: "2019-04-04T06:44:43Z"
  labels:
    app: owdev-openwhisk
    chart: openwhisk-0.1.4
    heritage: Tiller
    release: owdev
  name: owdev-private-registry.auth
  namespace: openwhisk
  resourceVersion: "18273580"
  selfLink: /api/v1/namespaces/openwhisk/secrets/owdev-private-registry.auth
  uid: 20f03275-56a5-11e9-9164-005056a3e755
type: kubernetes.io/dockerconfigjson
```
