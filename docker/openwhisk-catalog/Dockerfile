from ubuntu:latest

RUN apt-get -y update && apt-get -y install \
  git \
  wget

COPY init.sh /init.sh
RUN chmod +X /init.sh

CMD ["/init.sh"]
