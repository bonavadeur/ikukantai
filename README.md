# ikukantai - 行く艦隊

### (The Iku Fleet - Hạm Đội Ikư - 行く艦隊)

[![LICENSE](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](https://www.apache.org/licenses/LICENSE-2.0)
![Kubernetes](https://img.shields.io/badge/kubernetes-%23326ce5.svg?style=for-the-badge&logo=kubernetes&logoColor=white)
![Ubuntu](https://img.shields.io/badge/Ubuntu-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)
![Go](https://img.shields.io/badge/go-%2300ADD8.svg?style=for-the-badge&logo=go&logoColor=white)
![Prometheus](https://img.shields.io/badge/Prometheus-E6522C?style=for-the-badge&logo=Prometheus&logoColor=white)

`ikukantai` is a Knative Serving based Serverless Platform designed for Distributed System.

![ikukantai](images/ikukantai_wp.jpg)

## 1. Motivation

By default, **Kubernetes** and **Knative** uses "Evenly Load Balance Algorithms" in order to routing traffic to Pods/Functions. This mechanism is effective in a stable and homogeneous computing environment (like Cloud Computing). It should be noted that, "Evenly Load Balance Algorithms" in Kubernetes and Knative works with difference technology, but the results are the same.​

In order to help Kubernetes and Knative operating better in Distributed System like Edge-Cloud, we developed a more intelligent routing mechanism which take care of network latency between node, and resources in each node, and .etc.

Many related works work in deploying Knative in Edge-Cloud, but they are not unified-system approaches. They don’t show the latency exists in Knative internally.

In this project, we propose an approach that improves Knative from the inside. It is a Unified Serverless System for Distributed Systems. It is `ikukantai` (行く艦隊 - The iku Fleet - Hạm Đội ikư - translated from Japanese).

## 2. Architecture

![Arch](images/arch.png)

## 3. Installation

### 3.1. System requirements

+ Three nodes are Physical Machine or Virtual Machine, least 4 CPU and 6GB RAM each node  
+ Ubuntu-Server or Ubuntu Desktop version 20.04  
+ Kubernetes version 1.26.3  
+ Calico installed on Kubernetes cluster  
+ MetalLB installed on Kubernetes cluster

### 3.2. Install monlat - the Latency Monitoring system

#### 3.2.1. Install Prometheus

We follow Prometheus's installation guide in [Knative's Docs](https://knative.dev/docs/serving/observability/metrics/collecting-metrics/)

```bash
$ helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
$ helm repo update
$ helm install prometheus prometheus-community/kube-prometheus-stack -n default -f manifest/prometheus/values.yaml

$ kubectl apply -f https://raw.githubusercontent.com/knative-extensions/monitoring/main/grafana/dashboards.yaml

$ kubectl create namespace metrics
$ kubectl apply -f https://raw.githubusercontent.com/knative/docs/main/docs/serving/observability/metrics/collector.yaml
```

#### 3.2.2. Install monlat

We develop a Latency Monitoring system, for more detail and installation please visit [monlat](https://github.com/bonavadeur/monlat).

### 3.3. Install Knative Serving with Kourier is networking option and Our Extra-Controller

In this step we install Knative Serving's components (CRD, Knative's Pod) by applying .yaml files. Notes that the applied manifest is modified by ours, we do not use the original image. We develop extra features base on [Knative-Serving](https://github.com/knative/serving/tree/release-1.12) version 1.12.1 and [Kourier](https://github.com/knative-extensions/net-kourier/tree/release-1.12) version 1.12.1

```bash
# Install CRD
kubectl apply -f manifest/1-serving-crd.yaml
# Install Knative's Pod
kubectl apply -f manifest/2-serving-core.yaml
# Extra configmap and RBAC
kubectl apply -f manifest/miporin/configmap.yaml
kubectl apply -f manifest/miporin/rbac.yaml
# Install Networking Plugin
kubectl apply -f manifest/3-kourier.yaml
# Run domain config job
kubectl apply -f manifest/4-serving-default-domain.yaml
```

Wait until default-domain job is success

```bash
# check if default-domain job is success
kubectl -n knative-serving get job | grep default-domain
NAME             COMPLETIONS   DURATION   AGE
default-domain   1/1           13s        71s
# delete config job
kubectl delete -f manifest/4-serving-default-domain.yaml
# install new kourier controller
kubectl -n knative-serving patch deploy net-kourier-controller --patch '{"spec":{"template":{"spec":{"containers":[{"name":"controller","image":"docker.io/bonavadeur/ikukantai-kourier:v1.2-cnsm-15nov24"}]}}}}'
```

Install remaining components

```bash
kubectl apply -f manifest/miporin/miporin.yaml
```

### 3.4. Making some changes

#### 3.4.1. Kourier Gateway

```bash
# replicate 3scale-gateway pod to 3 replicas
kubectl -n kourier-system patch deploy 3scale-kourier-gateway --patch '{"spec":{"replicas":3}}'
kubectl -n kourier-system patch deploy 3scale-kourier-gateway --patch '{"spec":{"template":{"spec":{"affinity":{"nodeAffinity":{"requiredDuringSchedulingIgnoredDuringExecution":{"nodeSelectorTerms":[{"matchExpressions":[{"key":"kubernetes.io/hostname","operator":"In","values":["node1", "node2", "node3"]}]}]}}}}}}}'
# use local gateway for every request
kubectl -n kourier-system patch service kourier --patch '{"spec":{"internalTrafficPolicy":"Local","externalTrafficPolicy":"Local"}}'
kubectl -n kourier-system patch service kourier-internal --patch '{"spec":{"internalTrafficPolicy":"Local"}}'
```

Note that fill correct nodename in your cluster into second command. Let fill all nodenames.

#### 3.4.2. Activator

```bash
# replicate activator pod to 3 replicas
kubectl -n knative-serving patch deploy activator --patch '{"spec":{"replicas":3}}'
kubectl -n knative-serving patch deploy activator --patch '{"spec":{"template":{"spec":{"affinity":{"nodeAffinity":{"requiredDuringSchedulingIgnoredDuringExecution":{"nodeSelectorTerms":[{"matchExpressions":[{"key":"kubernetes.io/hostname","operator":"In","values":["node1", "node2", "node3"]}]}]}}}}}}}'
```

Note that fill correct nodename in your cluster into second command. Let fill all nodenames.

#### 3.4.3. Check your setup

You must see **3scale-gateway** and **activator** present in all nodes, each node has one **activator** and one **3scale-gateway**

```bash
ubuntu@node1:~$ kubectl -n knative-serving get pod -o wide | grep activator
activator-5cd6cb5f45-5nnnb                1/1     Running     0                156m   10.233.75.29     node2   <none>           <none>
activator-5cd6cb5f45-fkp2r                1/1     Running     0                156m   10.233.102.181   node1   <none>           <none>
activator-5cd6cb5f45-j6bqq                1/1     Running     0                156m   10.233.71.47     node3   <none>           <none>

ubuntu@node1:~$ kubectl -n kourier-system get pod -o wide
NAME                                     READY   STATUS    RESTARTS         AGE    IP               NODE    NOMINATED NODE   READINESS GATES
3scale-kourier-gateway-864554589-5dgxl   1/1     Running   11 (5h26m ago)   2d5h   10.233.75.28     node2   <none>           <none>
3scale-kourier-gateway-864554589-btfqf   1/1     Running   12 (5h21m ago)   2d5h   10.233.71.29     node3   <none>           <none>
3scale-kourier-gateway-864554589-p7q56   1/1     Running   13 (5h29m ago)   2d5h   10.233.102.176   node1   <none>           <none>

# miporin is our extra-controller
ubuntu@node1:~$ kubectl -n knative-serving get pod | grep miporin
miporin-597dcddbc-qvlc6                   1/1     Running     0                143m
```

## 4. Try it out

### 4.1. Deploy hello-application

```bash
# install a demoapp
$ kubectl apply -f manifest/demo/hello.yaml
```

### 4.2. Check system operation

```bash
# check ksvc is ready
$ kubectl get ksvc,servicemonitor,pod -o wide | grep hello
service.serving.knative.dev/hello   http://hello.default.192.168.133.2.sslip.io   hello-00001     hello-00001   True
servicemonitor.monitoring.coreos.com/hello
pod/hello-00001-deployment-7484848464-8btwr                  2/2     Running   0                 5m46s   10.233.71.1       node3   <none>           <none>
pod/hello-00001-deployment-7484848464-dlsh5                  2/2     Running   0                 5m50s   10.233.102.184    node1   <none>           <none>
pod/hello-00001-deployment-7484848464-vpbxg                  2/2     Running   0                 5m47s   10.233.75.7       node2   <none>           <none>
# curl to app
$ curl hello.default.svc.cluster.local
Konnichiwa from hello-00001-deployment-7484848464-dlsh5 in node1
```

### 4.3. Perform your experiments

Perform your experiments

## 5. ikukantai ecosystem

### 5.1. Support tools

The following tools support `ikukantai` Fleet operation and can work independently from `ikukantai` in any Kubernetes Cluster.

[Monlat](https://github.com/bonavadeur/monlat) - the latency monitoring system for Kubernetes

[Seika](https://github.com/bonavadeur/seika) - the Kubernetes Custom Resource maintains quantity of Pods in each Node

### 5.2. The tank on the Fleet

`ikukantai` is close-source, but you can exploit all extra power by using tanks deployed on the flight deck of the Fleet. We have a plan for developing 4 extra-components that make algorithm implementing easier.

[Miporin](https://github.com/bonavadeur/miporin) - the extra-controller of the Fleet

[Yukari](https://github.com/bonavadeur/yukari) (comming soon) - Scheduling Implementation Module on the Fleet, written in Python

[Katyusha](https://github.com/bonavadeur/katyusha) (comming soon) - Load Balancing Implementation Module on the Fleet, written in Python

[Nonna](https://github.com/bonavadeur/nonna) (comming soon) - Queuing Modifier Module on the Fleet, written in Python

Panzer vor!

## 6. Contributeur

Đào Hiệp - Bonavadeur - ボナちゃん  
The Future Internet Laboratory, Room E711, C7 Building, Hanoi University of Science and Technology, Vietnam.  
未来のインターネット研究室, C7 の E ７１１、ハノイ百科大学、ベトナム。  

![](images/github-wp.png)
