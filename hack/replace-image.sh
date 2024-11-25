#!/bin/bash

TAG="v2.1"

# replace image of net-kourier, controller, activator, autoscaler
kubectl -n knative-serving patch deploy net-kourier-controller --patch \
    '{"spec":{"template":{"spec":{"containers":[{"name":"controller","image":"docker.io/bonavadeur/ikukantai-kourier:'${TAG}'"}]}}}}'
kubectl -n knative-serving patch deploy controller --patch \
    '{"spec":{"template":{"spec":{"containers":[{"name":"controller","image":"docker.io/bonavadeur/ikukantai-controller:'${TAG}'"}]}}}}'
kubectl -n knative-serving patch daemonset activator --patch \
    '{"spec":{"template":{"spec":{"containers":[{"name":"activator","image":"docker.io/bonavadeur/ikukantai-activator:'${TAG}'"}]}}}}'
kubectl -n knative-serving patch deploy autoscaler --patch \
    '{"spec":{"template":{"spec":{"containers":[{"name":"autoscaler","image":"docker.io/bonavadeur/ikukantai-autoscaler:'${TAG}'"}]}}}}'

# replace image of queue-proxy
kubectl -n knative-serving patch image queue-proxy --type=merge --patch \
    '{"spec":{"image":"docker.io/bonavadeur/ikukantai-queue:'${TAG}'"}}'
kubectl -n knative-serving patch configmap config-deployment --patch \
    '{"data":{"queue-sidecar-image":"docker.io/bonavadeur/ikukantai-queue:'${TAG}'"}}'

# replace image of miporin
kubectl -n knative-serving patch deploy miporin --patch \
    '{"spec":{"template":{"spec":{"containers":[{"name":"miporin","image":"docker.io/bonavadeur/miporin:'${TAG}'"}]}}}}'
