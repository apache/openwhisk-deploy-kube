OpenWhisk Catalog
-----

Once the system is deployed, we need to run a Job to install all the
standard package catalog from incubator-openwhisk-catalog into the
/whisk.system namespace.

# Deploying

To run the Job, you just need to run:

```
kubectl apply -f install-catalog.yml
```
