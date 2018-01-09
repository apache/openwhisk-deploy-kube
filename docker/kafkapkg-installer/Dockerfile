from ubuntu:latest

RUN apt-get -y update && apt-get -y install \
  git \
  wget \
  zip

COPY init.sh /init.sh
RUN chmod +x /init.sh

CMD ["/init.sh"]
