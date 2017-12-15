from ubuntu:latest

RUN apt-get -y update && apt-get -y install \
  git \
  wget \
  zip \
  python-dev \
  python-pip

RUN pip install --upgrade setuptools
RUN pip install argcomplete
RUN pip install ansible==2.3.0.0

COPY init.sh /init.sh
RUN chmod +X /init.sh

CMD ["/init.sh"]
