#!/bin/bash

# Always clone the latest version of OpenWhisk
git clone https://github.com/apache/incubator-openwhisk /openwhisk

pushd /openwhisk
  # Install ansible requirements
  ./tools/ubuntu-setup/pip.sh
  ./tools/ubuntu-setup/ansible.sh

  # if auth guest overwrite file
  if [ -n "$AUTH_GUEST" ]; then
    echo "$AUTH_GUEST" > /openwhisk/ansible/files/auth.guest
  fi

  # if auth whisk system overwrite file
  if [ -n "$AUTH_WHISK_SYSTEM" ]; then
    echo "$AUTH_WHISK_SYSTEM" > /openwhisk/ansible/files/auth.guest
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
popd
