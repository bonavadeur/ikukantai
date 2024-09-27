# ikukantai - 行く艦隊

### (The Iku Fleet - Hạm Đội Ikư - 行く艦隊)

[![LICENSE](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](https://www.apache.org/licenses/LICENSE-2.0)
![Kubernetes](https://img.shields.io/badge/kubernetes-%23326ce5.svg?style=for-the-badge&logo=kubernetes&logoColor=white)
![Linux](https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)
![Go](https://img.shields.io/badge/go-%2300ADD8.svg?style=for-the-badge&logo=go&logoColor=white)
![Prometheus](https://img.shields.io/badge/Prometheus-E6522C?style=for-the-badge&logo=Prometheus&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-%23FF9900.svg?style=for-the-badge&logo=amazon-aws&logoColor=white)

`ikukantai` is a Knative Serving based Serverless Platform designed for Distributed System.

![ikukantai](images/ikukantai_wp.jpg)

## 1. Motivation

By default, **Kubernetes** and **Knative** uses "Evenly Load Balance Algorithms" in order to steer traffic to Pods/Functions. This mechanism is effective in a stable and homogeneous computing environment (like Cloud Computing). It should be noted that, "Evenly Load Balance Algorithms" in Kubernetes and Knative works with different algorithm, but the results are the same.​

In order to help Kubernetes and Knative operating better in Distributed System like Edge-Cloud, we developed a more intelligent routing mechanism which take care of network latency between nodes, and resources in each node, and .etc.

Many related works work in deploying Knative in Edge-Cloud, but they are not unified-system approaches. They don’t show the latency exists in Knative internally.

In this project, we propose an approach that improves Knative from the inside, a Unified Serverless Platform for Distributed Systems. It is `ikukantai` (行く艦隊 - The iku Fleet - Hạm Đội Ikư - translated from Japanese).

## 2. Architecture

![Arch](images/arch.png)

## 3. Installation

### 3.1. System requirements

+ Some nodes are Physical Machine or Virtual Machine, least 4 CPU and 16GB RAM for master-node and  3 CPU 6GB RAM for each worker-nodes  
+ Ubuntu-Server or Ubuntu Desktop version 20.04  
+ Kubernetes version 1.26.3  
+ Calico installed on Kubernetes cluster  
+ MetalLB installed on Kubernetes cluster (for laboratory experiments, we deploy system on a bare-metal cluster)  
+ Helm is installed

### 3.2. Install support mechanisms

#### 3.2.1. Monlat - the network latency monitoring system for Kubernetes

We develop a network latency monitoring system named `monlat`, for more detail and installation please visit [monlat](https://github.com/bonavadeur/monlat). First, let's install Prometheus Stack on Kubernetes Cluster, then install `monlat` later. The network latency metrics will be collected by Prometheus.

#### Install Prometheus Stack

We follow Prometheus Stacks installation guide from [Knative's Docs](https://knative.dev/docs/serving/observability/metrics/collecting-metrics/)

```bash
$ helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
$ helm repo update
$ helm install prometheus prometheus-community/kube-prometheus-stack -n default -f manifest/prometheus/values.yaml

$ kubectl apply -f https://raw.githubusercontent.com/knative-extensions/monitoring/main/grafana/dashboards.yaml

$ kubectl create namespace metrics
$ kubectl apply -f https://raw.githubusercontent.com/knative/docs/main/docs/serving/observability/metrics/collector.yaml
```

#### Install monlat

Follow [monlat installation guide](https://github.com/bonavadeur/monlat) to install `monlat` corectly.

### 3.3. Install Knative Serving with Kourier is networking option and Our Extra-Controller

In this step we install Knative Serving's components (CRD, Knative's Pods) by applying .yaml files. Notes that the applied manifests is modified by ours, we do not use the original images and configurations. Our images are developed base on [Knative-Serving](https://github.com/knative/serving/tree/release-1.12) version 1.12.1 and [Kourier](https://github.com/knative-extensions/net-kourier/tree/release-1.12) version 1.12.1

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

`miporin` is the extra-controller working alongside and is independently of Knative's controller. For more information about `miporin`, please visit [bonavadeur/miporin](https://github.com/bonavadeur/miporin)

### 3.4. Making some changes

#### 3.4.1. Kourier Gateway

```bash
# use local 3scale-kourier-gateway pod for every request
kubectl -n kourier-system patch service kourier --patch '{"spec":{"internalTrafficPolicy":"Local","externalTrafficPolicy":"Local"}}'
kubectl -n kourier-system patch service kourier-internal --patch '{"spec":{"internalTrafficPolicy":"Local"}}'
```

#### 3.4.3. Check your setup

You must see **3scale-kourier-gateway** and **activator** present in all nodes, each node has one **activator** and one **3scale-kourier-gateway**

```bash
$ kubectl -n knative-serving get pod -o wide | grep activator
activator-5cd6cb5f45-5nnnb                1/1     Running     0                156m   10.233.75.29     node2   <none>           <none>
activator-5cd6cb5f45-fkp2r                1/1     Running     0                156m   10.233.102.181   node1   <none>           <none>
activator-5cd6cb5f45-j6bqq                1/1     Running     0                156m   10.233.71.47     node3   <none>           <none>

$ kubectl -n kourier-system get pod -o wide
NAME                                     READY   STATUS    RESTARTS         AGE    IP               NODE    NOMINATED NODE   READINESS GATES
3scale-kourier-gateway-864554589-5dgxl   1/1     Running   11 (5h26m ago)   2d5h   10.233.75.28     node2   <none>           <none>
3scale-kourier-gateway-864554589-btfqf   1/1     Running   12 (5h21m ago)   2d5h   10.233.71.29     node3   <none>           <none>
3scale-kourier-gateway-864554589-p7q56   1/1     Running   13 (5h29m ago)   2d5h   10.233.102.176   node1   <none>           <none>

$ kubectl -n knative-serving get pod | grep miporin
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
# check knative-service is ready
$ kubectl get ksvc,servicemonitor,pod -o wide | grep hello
service.serving.knative.dev/hello   http://hello.default.192.168.133.2.sslip.io   hello-00001     hello-00001   True
servicemonitor.monitoring.coreos.com/hello
pod/hello-00001-deployment-7484848464-8btwr                  2/2     Running   0                 5m46s   10.233.71.1       node3   <none>           <none>
pod/hello-00001-deployment-7484848464-dlsh5                  2/2     Running   0                 5m50s   10.233.102.184    node1   <none>           <none>
pod/hello-00001-deployment-7484848464-vpbxg                  2/2     Running   0                 5m47s   10.233.75.7       node2   <none>           <none>

# curl to app from curl-pod
$ curl hello.default.svc.cluster.local
Konnichiwa from hello-00001-deployment-7484848464-dlsh5 in node1
```

### 4.3. Perform your experiments

Perform your experiments

## 5. ikukantai ecosystem

### 5.1. Support tools

The following tools support `ikukantai` Fleet operation and can work independently from `ikukantai` in any Kubernetes Cluster.

[Monlat](https://github.com/bonavadeur/monlat) - the latency monitoring system for Kubernetes

[Seika](https://github.com/bonavadeur/seika) - the Kubernetes Custom Resource that maintains quantity of Pods in each Node

### 5.2. The tanks on the Fleet

`ikukantai` is closed-source, but you can exploit all extra power by using tanks deployed on the flight deck of the Fleet. We have a plan for developing 4 extra-components that make algorithm implementation easier in the near future.

[Miporin](https://github.com/bonavadeur/miporin) - tank commander, the extra-controller working alongside and is independently of Knative's controller, written in Go

[Yukari](https://github.com/bonavadeur/yukari) (comming soon) - Scheduling Algorithm Implementation Module on the Fleet, written in Python

[Katyusha](https://github.com/bonavadeur/katyusha) (comming soon) - Load Balancing Algorithm Implementation Module on the Fleet, written in Python

[Nonna](https://github.com/bonavadeur/nonna) (comming soon) - Queuing Modifier Module on the Fleet, written in Python

Panzer vor!

## 6. Author

Đào Hiệp - Bonavadeur - ボナちゃん  
The Future Internet Laboratory, Room E711, C7 Building, Hanoi University of Science and Technology, Vietnam.  
未来のインターネット研究室, C7 の E ７１１、ハノイ百科大学、ベトナム。  

![](images/github-wp.png)
