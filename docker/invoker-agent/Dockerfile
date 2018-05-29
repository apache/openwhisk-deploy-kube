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

######
# build-stage
######
FROM golang:alpine AS build-env

RUN apk add --no-cache curl git openssh

# Build the invoker-agent executable
RUN mkdir -p /openwhisk/src/invoker-agent
COPY main.go /openwhisk/src/invoker-agent
ENV GOPATH=/openwhisk
RUN go get github.com/gorilla/mux
RUN go install invoker-agent

# Get docker CLI for interactive debugging when running
ENV DOCKER_VERSION 1.12.0
RUN curl -sSL -o docker-${DOCKER_VERSION}.tgz https://get.docker.com/builds/Linux/x86_64/docker-${DOCKER_VERSION}.tgz && \
tar --strip-components 1 -xvzf docker-${DOCKER_VERSION}.tgz -C /usr/bin docker/docker && \
rm -f docker-${DOCKER_VERSION}.tgz && \
chmod +x /usr/bin/docker


######
# Final stage
######
FROM alpine

RUN mkdir -p /openwhisk/bin
COPY --from=build-env /openwhisk/bin/invoker-agent /openwhisk/bin/invoker-agent

# For ease of debugging/inspection.  Not needed by invoker-agent
COPY --from=build-env /usr/bin/docker /usr/bin/docker

CMD ["/openwhisk/bin/invoker-agent"]
