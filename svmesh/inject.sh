#!/bin/bash

kubectl label namespace knative-serving istio-injection=enabled
kubectl label namespace kourier-system istio-injection=enabled
kubectl -n knative-serving delete pod --all
kubectl -n kourier-system delete pod --all
