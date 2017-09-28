#!/bin/bash
set -ex

# Always clone the latest version of OpenWhisk
git clone https://github.com/apache/incubator-openwhisk /openwhisk

pushd /openwhisk
  # Install ansible requirements
  ./tools/ubuntu-setup/pip.sh

  # upgrade cffi for ansible error on Debian Jesse
  pip install --upgrade cffi
  sudo pip install markupsafe
  sudo pip install ansible==2.3.0.0


  # if auth guest overwrite file
  if [ -n "$AUTH_GUEST" ]; then
    echo "$AUTH_GUEST" > /openwhisk/ansible/files/auth.guest
  fi

  # if auth whisk system overwrite file
  if [ -n "$AUTH_WHISK_SYSTEM" ]; then
    echo "$AUTH_WHISK_SYSTEM" > /openwhisk/ansible/files/auth.whisk.system
  fi

  # start couchdb with a background process
  /docker-entrypoint.sh /opt/couchdb/bin/couchdb &

  # wait for couchdb to be up and running
  TIMEOUT=0
  echo "wait for CouchDB to be up and running"
  until $( curl --output /dev/null --silent http://$DB_HOST:$DB_PORT/_utils ) || [ $TIMEOUT -eq 25 ]; do
    echo "waiting for CouchDB to be available"

    sleep 0.2
    let TIMEOUT=TIMEOUT+1
  done

  if [ $TIMEOUT -eq 25 ]; then
    echo "failed to setup CouchDB"
    exit 1
  fi


  # setup and initialize DB
  pushd ansible
    ansible-playbook -i environments/local setup.yml \
      -e db_prefix=$DB_PREFIX \
      -e db_host=$DB_HOST \
      -e db_username=$COUCHDB_USER \
      -e db_password=$COUCHDB_PASSWORD \
      -e db_port=$DB_PORT \
      -e openwhisk_home=/openwhisk
  popd

  # disable reduce limits on views
  curl -X PUT http://$COUCHDB_USER:$COUCHDB_PASSWORD@$DB_HOST:$DB_PORT/_node/couchdb@couchdb0/_config/query_server_config/reduce_limit -d '"false"'

  # create the couchdb system databases
  curl -X PUT http://$COUCHDB_USER:$COUCHDB_PASSWORD@$DB_HOST:$DB_PORT/_users
  curl -X PUT http://$COUCHDB_USER:$COUCHDB_PASSWORD@$DB_HOST:$DB_PORT/_replicator
  curl -X PUT http://$COUCHDB_USER:$COUCHDB_PASSWORD@$DB_HOST:$DB_PORT/_global_changes

  pushd ansible
    # initialize the DB
    ansible-playbook -i environments/local initdb.yml \
      -e db_prefix=$DB_PREFIX \
      -e db_host=$DB_HOST \
      -e db_username=$COUCHDB_USER \
      -e db_password=$COUCHDB_PASSWORD \
      -e db_port=$DB_PORT \
      -e openwhisk_home=/openwhisk

    # wipe the DB
    ansible-playbook -i environments/local wipe.yml \
      -e db_prefix=$DB_PREFIX \
      -e db_host=$DB_HOST \
      -e db_username=$COUCHDB_USER \
      -e db_password=$COUCHDB_PASSWORD \
      -e db_port=$DB_PORT \
      -e openwhisk_home=/openwhisk
  popd
popd

echo "successfully setup and configured CouchDB v2.0"

sleep inf
