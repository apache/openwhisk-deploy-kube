FROM ubuntu:16.04

RUN apt-get update && apt-get install -y curl

RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl && \
	chmod +x kubectl && \
	mv kubectl /usr/local/bin/kubectl

ADD certs.sh /usr/local/bin/certs.sh
RUN chmod +x /usr/local/bin/certs.sh

