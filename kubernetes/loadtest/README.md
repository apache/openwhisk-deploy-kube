LoadTest
-----

A collection of jobs to do performance testing
against openwhisk deployed on kube, based on
the code in apache/incubator-openwhisk-performance.git.

The jobs are intended to run in the openwhisk namespace in the same
cluster as the system under test to eliminate external network
latency.

# Preparing

The Jobs assume the noopLatency and noopThroughput actions are already
created in the default namespace.  These actions are simple noops
(for example a JavaScript action whose body is `function main(){return {};}`).

# Runnning

To run one of the Jobs, edit the yml to adjust test parameters and then

```
kubectl apply -f loadtest-latency.yml
```
