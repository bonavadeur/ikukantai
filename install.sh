#!/bin/bash

kubectl apply -f 1-serving-crd.yaml
sleep 2
kubectl apply -f 2-serving-core.yaml
sleep 2
kubectl apply -f 3-activator.yaml
sleep 2
kubectl apply -f 4-kourier.yaml
sleep 2
kubectl patch configmap/config-network \
  --namespace knative-serving \
  --type merge \
  --patch '{"data":{"ingress-class":"kourier.ingress.networking.knative.dev"}}'
sleep 10
kubectl apply -f 5-serving-default-domain.yaml
exit
