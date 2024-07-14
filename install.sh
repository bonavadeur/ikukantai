#!/bin/bash

kubectl apply -f manifest/1-serving-crd.yaml
sleep 5
kubectl apply -f manifest/2-serving-core.yaml
sleep 5
kubectl apply -f manifest/3-activator.yaml
sleep 5
kubectl apply -f manifest/4-kourier.yaml
sleep 5
kubectl patch configmap/config-network \
  --namespace knative-serving \
  --type merge \
  --patch '{"data":{"ingress-class":"kourier.ingress.networking.knative.dev"}}'
sleep 15
kubectl apply -f manifest/5-serving-default-domain.yaml
exit
