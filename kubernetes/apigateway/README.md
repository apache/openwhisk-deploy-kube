ApiGateway
-----

# Deploying

To deploy the ApiGateway, you only need to run the following command:

```
kubectl apply -f apigateway.yml
```

Note: The URL returned from `wsk api create` may contain a spurious
:8080 due to its assumption about the meaning of PUBLIC_MANAGEDURL_HOST.
Working on a fix to the upstream incubator-openwhisk-apigateway project
to weaken the assumption that the API URL is constructed by concatenating
PUBLIC_MANAGEDURL_HOST:PUBLIC_MANAGEDURL_PORT as this is not always
appropriate for kube-based deployments.
