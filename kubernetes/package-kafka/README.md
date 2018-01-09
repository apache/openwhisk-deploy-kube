# Deploy kafka package to Apache OpenWhisk

This project is to deploy kafka package to local Apache OpenWhisk on a K8s using YAML file.

## Prerequisite
Edit package-kafka.env as needed to set the appropriate values for your deployment, then create the configmap packages.kafkaprovider:
```
kubectl -n openwhisk create cm packages.kafkaprovider --from-literal=kafkapkg_db_prefix=mq
```

The deployment also has dependencies to secret `whisk.auth` and `db.auth`, and configmap `whisk.ingress`. Make sure you have these settings before you start the deployment.

## Step 1. Install kafka provider
```
kubectl apply -f kafkaprovider.yml
```

## Step 2. Install messaging package to your local Apache OpenWhisk
```
kubectl apply -f kafkapkginstaller.yml
```

## Verify your Kafka package
Get the description of your Kafka package by:
```
wsk package get /whisk.system/messaging --summary -i
```
Create a kafka package binding:
```
wsk package bind /whisk.system/messaging myKafkaPkg -p brokers "[\"kafka_host1:9093\", \"kafka_host2:9093\"]" -i
```
Create a trigger:
```
wsk trigger create MyKafkaTrigger -f myKafkaPkg/kafkaFeed -p topic in-topic -i
```
Send a message to kafka topic by invoking the action `kafkaProduce`:
```
wsk action invoke myKafkaPkg/kafkaProduce -p topic in-topic -p value "this is a message" -i
```
Check activation log to see `MyKafkaTrigger` is triggered when a new message is sent.
```
wsk activation poll -i
```
