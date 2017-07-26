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
you will need to update a number of properties, for Kafka and Nginx.

* Kafka: Look at the Kafka [README](https://github.com/apache/incubator-openwhisk-deploy-kube/blob/master/kubernetes/kafka/README.md)

* Controller: You will need to update the replication count for the
  Controllers [here](https://github.com/apache/incubator-openwhisk-deploy-kube/tree/master/kubernetes/controller/controller.yml#L10)
  and redeploy.

* Nginx: Take a look at the Nginx [README](https://github.com/apache/incubator-openwhisk-deploy-kube/blob/master/kubernetes/nginx/README.md#increase-controller-count)

[StatefulSet]: https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/
