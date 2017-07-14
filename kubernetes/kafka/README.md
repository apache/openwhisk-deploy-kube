Kafka
-----

# Deploying

To deploy Kafka, you will need to make sure that [Zookeeper](../zookeeper/README.md)
is deployed. Otherwise Kafka will keep crashing since
it cannot sync to a cluster. To actually deploy Kafka,
just run:

```
kubectl apply -f kafka.yml
```

# Deployment Changes
## Increase Invoker Pods

When updating the invoker pod count you will need to update some Kafka
and Invoker properties.

* Kafka: The ["INVOKER_COUNT"](https://github.com/apache/incubator-openwhisk-deploy-kube/blob/master/kubernetes/kafka/kafka.yml#L73)
  property will need to equal the number of Invokers being deployed
  and then you need to redeploy Kafka so that the new `invokerN`
  topics are created.

* Invoker: See the Invoker [README](https://github.com/apache/incubator-openwhisk-deploy-kube/blob/master/kubernetes/invoker/README.md)

## Increase Controller Pods

When updating the Controller pod count, you will need to update the
Kafka, Controller and Nginx deployments.

* Kafka: The ["CONTROLLER_COUNT"](https://github.com/apache/incubator-openwhisk-deploy-kube/blob/master/kubernetes/kafka/kafka.yml#L63)
  property will need to equal the number of Controllers being deployed
  and then you need to redeploy Kafka so that the new `completedN`
  topics are created.

* Controller: See the Controller [README](https://github.com/apache/incubator-openwhisk-deploy-kube/blob/master/kubernetes/controller/README.md)

* Nginx: See the Nginx [README](https://github.com/apache/incubator-openwhisk-deploy-kube/blob/master/kubernetes/nginx/README.md#increase-controller-count)
