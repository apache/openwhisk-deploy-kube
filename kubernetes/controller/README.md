Controller
----------

# Deploying

When deploying the Controller, it needs to be deployed via a
[StatefulSet][StatefulSet]. This is because each Controller
instance needs to know which index it is. The Controller
can be deployed with:

```
kubectl apply -f invoker.yml
```

# Controller Deployment Changes
## Increase Controller Count

If you want to increase the number of controllers deployed,
then you will also need to update part of the Nginx configuration.
First, you will need to update the replication count for the
Controllers [here](https://github.com/apache/incubator-openwhisk-deploy-kube/tree/master/kubernetes/controller/controller.yml#L10).

After updating the controller count, you will need to update
the available routes for Nginx. This is because the controllers
are not yet purely HA, but are in a failover mode. To update Nginx
with the proper routes, take a look at
[these properties](https://github.com/apache/incubator-openwhisk-deploy-kube/tree/master/kubernetes/nginx/nginx.conf#L15-L20).
The routes for the controllers and how they are determined can
be found in the [StatefulSet][StatefulSet] docs.

[StatefulSet]: https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/
