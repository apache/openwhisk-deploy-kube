CouchDB
-----

# Deploying

## Create secret and configmap

The db.auth secret and db.config configmap contain authorization and
configuration information for the CouchDB instance being used for this
OpenWhisk deployment.  The db.auth secret is expected to define two
keys: db_username and db_password. The db.config configmap is expected
to define the following keys: db_protocol, db_provider, db_host, db_port,
db_prefix, db_whisk_activations, db_whisk_actions, and db_whisk_auths.
The commands below create them with default values; adjust as needed for
your deployment.

```
kubectl -n openwhisk create secret generic db.auth --from-literal=db_username=whisk_admin --from-literal=db_password=some_passw0rd
```

```
kubectl -n openwhisk create configmap db.config --from-literal=db_protocol=http --from-literal=db_provider=CouchDB --from-literal=db_host=couchdb.openwhisk.svc.cluster.local --from-literal=db_port=5984 --from-literal=db_whisk_activations=test_activations --from-literal=db_whisk_actions=test_whisks --from-literal=db_whisk_auths=test_subjects --from-literal=db_prefix=test_
```

## Deploy the CouchDB pod

To deploy CouchDB, you first need to create the CouchDB
Pod. This can be done by running:

```
kubectl apply -f couchdb.yml
```

If the persistent volume mounted as /opt/couchdb/data in the
pod already has been initialized with an OpenWhisk CouchDB
database, then the pod will simply use it.  If an initialized
database is not found, then the pod will go through the
process of pulling the OpenWhisk git repo and running some of the
ansible playbooks for configuring CouchDB.

**NOTE** the pod will say running as soon as the start command runs,
but that does not mean that CouchDB is really running and ready to
use. If a new database actually needs to be created and initialized,
it typically takes about a minute until setup has completed and
the database is actually usable. Examine the pods logs with

```
kubectl -n openwhisk logs -lname=couchdb
```

and look for the line:

```
successfully setup and configured CouchDB for OpenWhisk
```

This indicates that the CouchDB instance is fully configured and ready to use.

