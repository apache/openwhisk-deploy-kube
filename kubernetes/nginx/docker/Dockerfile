FROM nginx:1.11

Run apt-get -y update && \
  apt-get -y install zip

# Download all of the OpenWhisk CLIs
ADD https://github.com/apache/incubator-openwhisk-cli/releases/download/latest/OpenWhisk_CLI-latest-linux-386.zip /etc/nginx/cli/go/download/linux/386/wsk.zip
ADD https://github.com/apache/incubator-openwhisk-cli/releases/download/latest/OpenWhisk_CLI-latest-linux-amd64.zip /etc/nginx/cli/go/download/linux/amd64/wsk.zip
ADD https://github.com/apache/incubator-openwhisk-cli/releases/download/latest/OpenWhisk_CLI-latest-mac-386.zip /etc/nginx/cli/go/download/mac/386/wsk.zip
ADD https://github.com/apache/incubator-openwhisk-cli/releases/download/latest/OpenWhisk_CLI-latest-mac-amd64.zip /etc/nginx/cli/go/download/mac/amd64/wsk.zip
ADD https://github.com/apache/incubator-openwhisk-cli/releases/download/latest/OpenWhisk_CLI-latest-windows-386.zip /etc/nginx/cli/go/download/windows/386/wsk.zip

# Untar all of the files
RUN unzip /etc/nginx/cli/go/download/linux/386/wsk.zip -d /etc/nginx/cli/go/download/linux/386
RUN unzip /etc/nginx/cli/go/download/linux/amd64/wsk.zip -d /etc/nginx/cli/go/download/linux/amd64
RUN unzip /etc/nginx/cli/go/download/mac/386/wsk.zip -d /etc/nginx/cli/go/download/mac/386
RUN unzip /etc/nginx/cli/go/download/mac/amd64/wsk.zip -d /etc/nginx/cli/go/download/mac/amd64
RUN unzip /etc/nginx/cli/go/download/windows/386/wsk.zip -d /etc/nginx/cli/go/download/windows/386

# Remove extra zip file
RUN rm /etc/nginx/cli/go/download/linux/386/wsk.zip
RUN rm /etc/nginx/cli/go/download/linux/amd64/wsk.zip
RUN rm /etc/nginx/cli/go/download/mac/386/wsk.zip
RUN rm /etc/nginx/cli/go/download/mac/amd64/wsk.zip
RUN rm /etc/nginx/cli/go/download/windows/386/wsk.zip

COPY blackbox-0.1.0.tar.gz /etc/nginx/blackbox-0.1.0.tar.gz
