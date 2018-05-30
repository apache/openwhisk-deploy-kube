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

FROM apache/couchdb:2.1

ADD http://ftp.us.debian.org/debian/pool/main/a/apt/apt-transport-https_1.0.9.8.4_amd64.deb /tmp/apt-transport-https_1.0.9.8.4_amd64.deb
ADD http://ftp.us.debian.org/debian/pool/main/c/curl/libcurl3-gnutls_7.38.0-4+deb8u8_amd64.deb /tmp/libcurl3-gnutls_7.38.0-4+deb8u58_amd64.deb
RUN dpkg -i /tmp/libcurl3-gnutls_7.38.0-4+deb8u58_amd64.deb
RUN dpkg -i /tmp/apt-transport-https_1.0.9.8.4_amd64.deb

RUN apt-get -y update && apt-get -y install \
  git \
  curl \
  sudo \
  python-dev \
  python-pip \
  libffi-dev \
  libssl-dev

RUN pip install --upgrade setuptools
RUN pip install argcomplete
RUN pip install couchdb
RUN pip install --upgrade cffi
RUN pip install markupsafe
RUN pip install ansible==2.5.2
RUN pip install -U pyopenssl

COPY init.sh /init.sh
RUN chmod +X /init.sh

CMD ["/init.sh"]
