FROM ubuntu:trusty
ENV DEBIAN_FRONTEND noninteractive
ENV UCF_FORCE_CONFFNEW YES
RUN ucf --purge /boot/grub/menu.lst
ARG KUBE_VERSION

# install openwhisk
RUN apt-get -y update && \
    apt-get -y upgrade && \
    apt-get install -y \
      git \
      curl \
      wget \
      apt-transport-https \
      ca-certificates \
      python-pip \
      python-dev \
      libffi-dev \
      libssl-dev \
      libxml2-dev \
      libxslt1-dev \
      libjpeg8-dev \
      zlib1g-dev \
      vim

# clone OpenWhisk and install dependencies
# Note that we are not running the install all script since we do not care about Docker.
RUN git clone https://github.com/openwhisk/openwhisk && \
    /openwhisk/tools/ubuntu-setup/misc.sh && \
    /openwhisk/tools/ubuntu-setup/pip.sh && \
    /openwhisk/tools/ubuntu-setup/java8.sh && \
    /openwhisk/tools/ubuntu-setup/scala.sh && \
    /openwhisk/tools/ubuntu-setup/ansible.sh

# Change this to https://github.com/openwhisk/openwhisk-devtools when committing to master
COPY ansible-kube /incubator-openwhisk-deploy-kube/ansible-kube
COPY configure /incubator-openwhisk-deploy-kube/configure

# install kube dependencies
RUN wget https://storage.googleapis.com/kubernetes-release/release/$KUBE_VERSION/bin/linux/amd64/kubectl && \
    chmod +x kubectl && \
    mv kubectl /usr/local/bin/kubectl
