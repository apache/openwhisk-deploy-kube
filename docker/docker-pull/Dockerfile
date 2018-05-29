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

from ubuntu:latest

ENV DOCKER_VERSION 1.12.0

RUN apt-get -y update && apt-get -y install \
  wget \
  python-pip

# Install docker client
RUN wget --no-verbose https://get.docker.com/builds/Linux/x86_64/docker-${DOCKER_VERSION}.tgz && \
tar --strip-components 1 -xvzf docker-${DOCKER_VERSION}.tgz -C /usr/bin docker/docker && \
rm -f docker-${DOCKER_VERSION}.tgz && \
chmod +x /usr/bin/docker

RUN pip install --upgrade setuptools
RUN pip install ansible==2.5.2
RUN pip install jinja2==2.9.6

COPY pull_images.yml /pull_images.yml

CMD ["/usr/local/bin/ansible-playbook", "/pull_images.yml"]
