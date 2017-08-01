CouchDB
-----

# Deploying

To deploy CouchDB, you first need to create the CouchDB
Pod. This can be done by running:

```
kubectl apply -f couchdb.yml
```

Once the Pod is up and running, the pod then needs to be
configured. To do this, you need to run the configuration
pod:

```
kubectl create -f couchdb-setup.yml
```

This pod goes through the process of pulling the OpenWhisk
repo and running through some of the ansible playbooks for
configuring CouchDB.

# Configuring CouchDB
## Usernames and Passwords

To configure custom usernames and passwords, you can edit
the CouchDB [setup pod](https://github.com/apache/incubator-openwhisk-deploy-kube/blob/master/kubernetes/couchdb/couchdb-setup.yml#L23-L26).

**NOTE** If the CouchDB username and password properties
are updated, then you will need to update the Controller
and Invoker yamls with updated username and password.

## Persistance

To create a persistant CouchDB instance, you will need
to create a [persistent volume](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)
for the [couchdb.yml](couchdb.yml).
