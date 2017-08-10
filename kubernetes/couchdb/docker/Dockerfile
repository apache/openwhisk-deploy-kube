FROM couchdb:1.6

RUN apt-get -y update && apt-get -y install \
  git \
  curl \
  sudo \
  python-dev \
  libffi-dev \
  libssl-dev

COPY init.sh /init.sh
RUN chmod +X /init.sh

CMD ["/init.sh"]
