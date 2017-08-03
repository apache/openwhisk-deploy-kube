CouchDB
-----

# Deploying

To deploy CouchDB, you first need to create the CouchDB
Pod. This can be done by running:

```
kubectl apply -f couchdb.yml
```

This pod goes through the process of pulling the OpenWhisk
repo and running through some of the ansible playbooks for
configuring CouchDB.

**NOTE** the pod will say running as soon as the start command
runs, but it does not actually mean that the DB is ready to use.
This is because it might not yet be configured. To check if the
DB has been setup, you can look at the Pod logs with

```
  export COUCH_DB_POD=$(kubectl -n openwhisk get pods -o wide --show-all | grep "couchdb" | awk '{print $1}')
  kubectl -n openwhisk logs $COUCH_DB_POD
```

In the logs, you should see the line:

```
Apache CouchDB has started on http://0.0.0.0:5984
```

This indicates that the CouchDB instancs is up and running.

# Configuring CouchDB
## Usernames and Passwords

To configure custom usernames and passwords, you can edit
the CouchDB [setup pod](https://github.com/apache/incubator-openwhisk-deploy-kube/blob/master/kubernetes/couchdb/couchdb.yml#L46-L49).

**NOTE** If the CouchDB username and password properties
are updated, then you will need to update the Controller
and Invoker yamls with updated username and password.

## Persistance

To create a persistant CouchDB instance, you will need
to create a [persistent volume](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)
for the [couchdb.yml](couchdb.yml).
