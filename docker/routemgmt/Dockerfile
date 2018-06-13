# Licensed to the Apache Software Foundation (ASF) under one or more contributor
# license agreements; and to You under the Apache License, Version 2.0.

from ubuntu:latest

RUN apt-get -y update && apt-get -y install \
  git \
  wget \
  zip

COPY init.sh /init.sh
RUN chmod +X /init.sh

CMD ["/init.sh"]
