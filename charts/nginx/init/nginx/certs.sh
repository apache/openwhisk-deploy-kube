#!/bin/bash
set -ex

if [ -z "$1" ]; then
cat <<- EndOfMessage
  First argument should be the domain for the OpenWhisk deployment.
  Note: By default the Nginx config file assumes the pattern '*.openwhisk'.
EndOfMessage

exit 1
fi

mkdir -p certs

openssl req -x509 -newkey rsa:2048 -keyout certs/key.pem -out certs/cert.pem -nodes -subj "/CN=$1" -days 365
