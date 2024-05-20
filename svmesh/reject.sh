#!/bin/bash

kubectl label namespace knative-serving istio-injection-
kubectl label namespace kourier-system istio-injection-
kubectl -n knative-serving delete pod --all
kubectl -n kourier-system delete pod --all
