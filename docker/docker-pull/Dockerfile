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
RUN pip install ansible==2.3.0.0
RUN pip install jinja2==2.9.6

COPY pull_images.yml /pull_images.yml

CMD ["/usr/local/bin/ansible-playbook", "/pull_images.yml"]
