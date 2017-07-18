FROM ubuntu:trusty

RUN apt-get -y update && apt-get -y install \
  git \
  curl

COPY init.sh /init.sh

CMD ["/init.sh"]
