# Licensed to the Apache Software Foundation (ASF) under one or more contributor
# license agreements; and to You under the Apache License, Version 2.0.

# installCatalog.sh expects the wsk cli to be $OPENWHISK_HOME/bin/wsk
export OPENWHISK_HOME=/usr/local

git clone https://github.com/apache/incubator-openwhisk-package-kafka.git

export DB_URL=http://$DB_USERNAME:$DB_PASSWORD@$DB_HOST:$DB_PORT
pushd /incubator-openwhisk-package-kafka
  ./installKafka.sh $AUTH $APIHOST $DB_URL $DB_PREFIX $APIHOST
  ./installCatalog.sh $AUTH $APIHOST $DB_URL $DB_PREFIX $APIHOST
popd

echo "successfully setup kafka package"
