FROM klaemo/couchdb:2.0

ADD http://ftp.us.debian.org/debian/pool/main/a/apt/apt-transport-https_1.0.9.8.4_amd64.deb /tmp/apt-transport-https_1.0.9.8.4_amd64.deb
ADD http://ftp.us.debian.org/debian/pool/main/c/curl/libcurl3-gnutls_7.38.0-4+deb8u5_amd64.deb /tmp/libcurl3-gnutls_7.38.0-4+deb8u5_amd64.deb
RUN dpkg -i /tmp/libcurl3-gnutls_7.38.0-4+deb8u5_amd64.deb
RUN dpkg -i /tmp/apt-transport-https_1.0.9.8.4_amd64.deb

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
