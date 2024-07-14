#!/bin/bash

kubectl delete -f manifest/5-serving-default-domain.yaml
sleep 3
kubectl delete -f manifest/4-kourier.yaml
sleep 3
kubectl delete -f manifest/3-activator.yaml
sleep 3
kubectl delete -f manifest/2-serving-core.yaml
sleep 3
kubectl delete -f manifest/1-serving-crd.yaml
sleep 3
kubectl delete ns knative-serving
