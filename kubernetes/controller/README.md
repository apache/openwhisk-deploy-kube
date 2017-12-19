Controller
----------

# Deploying

When deploying the Controller, it needs to be deployed via a
[StatefulSet][StatefulSet]. This is because each Controller
instance needs to know which index it is. The Controller
can be deployed with:

```
kubectl apply -f controller.yml
```

# Controller Deployment Changes
## Increase Controller Count

You will need to update the number of replicas for the
Controllers [here](https://github.com/apache/incubator-openwhisk-deploy-kube/tree/master/kubernetes/controller/controller.yml#L10)
and the value of CONTROLLER_INSTANCES [here](https://github.com/apache/incubator-openwhisk-deploy-kube/tree/master/kubernetes/controller/controller.yml#L60)
and the value of AKKA_CLUSTER_SEED_NODES [here](https://github.com/apache/incubator-openwhisk-deploy-kube/tree/master/kubernetes/controller/controller.yml#L88)
and redeploy.

[StatefulSet]: https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/
