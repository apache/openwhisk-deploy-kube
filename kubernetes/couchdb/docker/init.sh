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
  couchdb -b

  # wait for couchdb to be up and running
  TIMEOUT=0
  echo "wait for CouchDB to be up and running"
  until [ $TIMEOUT -eq 25 ]; do
    echo "waiting for CouchDB to be available"

    if [ -n $(/etc/init.d/couchdb status | grep 'running') ]; then
      echo "CouchDB is up and running"
      break
    fi

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
      -e db_host=$DB_HOST \
      -e db_prefix=$DB_PREFIX \
      -e db_username=$DB_USERNAME \
      -e db_password=$DB_PASSWORD \
      -e db_port=$DB_PORT \
      -e openwhisk_home=/openwhisk
  popd

  # create the admin user
  curl -X PUT http://$DB_HOST:$DB_PORT/_config/admins/$DB_USERNAME -d "\"$DB_PASSWORD\""

  # disable reduce limits on views
  curl -X PUT http://$DB_USERNAME:$DB_PASSWORD@$DB_HOST:$DB_PORT/_config/query-server_config/reduce_limit -d '"false"'

  pushd ansible
    # initialize the DB
    ansible-playbook -i environments/local initdb.yml \
      -e db_host=$DB_HOST \
      -e db_prefix=$DB_PREFIX \
      -e db_username=$DB_USERNAME \
      -e db_password=$DB_PASSWORD \
      -e db_port=$DB_PORT \
      -e openwhisk_home=/openwhisk

    # wipe the DB
    ansible-playbook -i environments/local wipe.yml \
      -e db_host=$DB_HOST \
      -e db_prefix=$DB_PREFIX \
      -e db_username=$DB_USERNAME \
      -e db_password=$DB_PASSWORD \
      -e db_port=$DB_PORT \
      -e openwhisk_home=/openwhisk
  popd

  # stop the CouchDB background process
  couchdb -d
popd

# start couchdb that has been setup
tini -s -- couchdb
