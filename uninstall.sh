#!/bin/bash

kubectl delete -f 5-serving-default-domain.yaml
kubectl delete -f 4-kourier.yaml
kubectl delete -f 3-activator.yaml
kubectl delete -f 2-serving-core.yaml
kubectl delete -f 1-serving-crd.yaml
sleep 2
kubectl delete ns knative-serving
