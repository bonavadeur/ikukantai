#!/bin/bash

vanilla() {
    allin=$1

    # patch replicas
    kubectl -n kourier-system patch deploy 3scale-kourier-gateway --patch '{"spec":{"replicas":1}}'
    kubectl -n knative-serving patch deploy activator --patch '{"spec":{"replicas":1}}'

    # patch nodeSelector
    if [ $1 == "cloud" ]; then
        kubectl -n kourier-system patch deploy 3scale-kourier-gateway --patch '{"spec":{"template":{"spec":{"affinity":{"nodeAffinity":{"requiredDuringSchedulingIgnoredDuringExecution":{"nodeSelectorTerms":[{"matchExpressions":[{"key":"kubernetes.io/hostname","operator":"In","values":["node1", "node2"]}]}]}}}}}}}'
        kubectl -n knative-serving patch deploy activator --patch '{"spec":{"template":{"spec":{"affinity":{"nodeAffinity":{"requiredDuringSchedulingIgnoredDuringExecution":{"nodeSelectorTerms":[{"matchExpressions":[{"key":"kubernetes.io/hostname","operator":"In","values":["node1", "node2"]}]}]}}}}}}}'
    elif [ $1 == "edge" ]; then
        kubectl -n kourier-system patch deploy 3scale-kourier-gateway --patch '{"spec":{"template":{"spec":{"affinity":{"nodeAffinity":{"requiredDuringSchedulingIgnoredDuringExecution":{"nodeSelectorTerms":[{"matchExpressions":[{"key":"kubernetes.io/hostname","operator":"In","values":["node3"]}]}]}}}}}}}'
        kubectl -n knative-serving patch deploy activator --patch '{"spec":{"template":{"spec":{"affinity":{"nodeAffinity":{"requiredDuringSchedulingIgnoredDuringExecution":{"nodeSelectorTerms":[{"matchExpressions":[{"key":"kubernetes.io/hostname","operator":"In","values":["node3"]}]}]}}}}}}}'
    fi

    # patch image
    kubectl -n knative-serving patch deploy activator --patch '{"spec":{"template":{"spec":{"containers":[{"name":"activator","image":"gcr.io/knative-releases/knative.dev/serving/cmd/activator@sha256:4cdbe7acc718f55005c0fed4633e9e9feb64f03830132b5dd007e4088a0b2e9f"}]}}}}'
    kubectl -n knative-serving patch deploy controller --patch '{"spec":{"template":{"spec":{"containers":[{"name":"controller","image":"gcr.io/knative-releases/knative.dev/serving/cmd/controller@sha256:5d9b948e78bb4f54b602d98e02dedd291689b90295dadab10992f0d9ef2aa1d8"}]}}}}'
    kubectl -n knative-serving patch deploy autoscaler --patch '{"spec":{"template":{"spec":{"containers":[{"name":"autoscaler","image":"gcr.io/knative-releases/knative.dev/serving/cmd/autoscaler@sha256:28f45751cac2090019a74ec2801d1f8cd18210ae55159cacd0c9baf74ccc9d7c"}]}}}}'
    kubectl -n knative-serving patch deploy net-kourier-controller --patch '{"spec":{"template":{"spec":{"containers":[{"name":"controller","image":"gcr.io/knative-releases/knative.dev/net-kourier/cmd/kourier@sha256:9cd4d69a708a8cf8e597efe3f511494d71cf8eab1b2fd85545097069ad47d3f6"}]}}}}'
    kubectl -n knative-serving patch deploy activator --patch '{"spec":{"template":{"spec":{"containers":[{"name":"activator","imagePullPolicy": "IfNotPresent"}]}}}}'
    kubectl -n knative-serving patch deploy net-kourier-controller --patch '{"spec":{"template":{"spec":{"containers":[{"name":"controller","imagePullPolicy": "IfNotPresent"}]}}}}'

    # patch service
    kubectl -n kourier-system patch service kourier --patch '{"spec":{"internalTrafficPolicy":"Cluster","externalTrafficPolicy":"Cluster"}}'
    kubectl -n kourier-system patch service kourier-internal --patch '{"spec":{"internalTrafficPolicy":"Cluster"}}'
}

# vanillaedge() {
#     # patch replicas
#     kubectl -n kourier-system patch deploy 3scale-kourier-gateway --patch '{"spec":{"replicas":1}}'
#     kubectl -n knative-serving patch deploy activator --patch '{"spec":{"replicas":1}}'

#     # patch nodeSelector
#     kubectl -n kourier-system patch deploy 3scale-kourier-gateway --patch '{"spec":{"template":{"spec":{"affinity":{"nodeAffinity":{"requiredDuringSchedulingIgnoredDuringExecution":{"nodeSelectorTerms":[{"matchExpressions":[{"key":"kubernetes.io/hostname","operator":"In","values":["node3"]}]}]}}}}}}}'
#     kubectl -n knative-serving patch deploy activator --patch '{"spec":{"template":{"spec":{"affinity":{"nodeAffinity":{"requiredDuringSchedulingIgnoredDuringExecution":{"nodeSelectorTerms":[{"matchExpressions":[{"key":"kubernetes.io/hostname","operator":"In","values":["node3"]}]}]}}}}}}}'

#     # patch image
#     kubectl -n knative-serving patch deploy activator --patch '{"spec":{"template":{"spec":{"containers":[{"name":"activator","image":"gcr.io/knative-releases/knative.dev/serving/cmd/activator@sha256:4cdbe7acc718f55005c0fed4633e9e9feb64f03830132b5dd007e4088a0b2e9f"}]}}}}'
#     kubectl -n knative-serving patch deploy net-kourier-controller --patch '{"spec":{"template":{"spec":{"containers":[{"name":"controller","image":"gcr.io/knative-releases/knative.dev/net-kourier/cmd/kourier@sha256:9cd4d69a708a8cf8e597efe3f511494d71cf8eab1b2fd85545097069ad47d3f6"}]}}}}'

#     # patch service
#     kubectl -n kourier-system patch service kourier --patch '{"spec":{"internalTrafficPolicy":"Cluster","externalTrafficPolicy":"Cluster"}}'
#     kubectl -n kourier-system patch service kourier-internal --patch '{"spec":{"internalTrafficPolicy":"Cluster"}}'
# }

# proposal() {
#     # patch replicas
#     kubectl -n kourier-system patch deploy 3scale-kourier-gateway --patch '{"spec":{"replicas":3}}'
#     kubectl -n knative-serving patch deploy activator --patch '{"spec":{"replicas":2}}'

#     # patch nodeSelector
#     kubectl -n kourier-system patch deploy 3scale-kourier-gateway --patch '{"spec":{"template":{"spec":{"affinity":{"nodeAffinity":{"requiredDuringSchedulingIgnoredDuringExecution":{"nodeSelectorTerms":[{"matchExpressions":[{"key":"kubernetes.io/hostname","operator":"In","values":["node1", "node2", "node3"]}]}]}}}}}}}'
#     kubectl -n knative-serving patch deploy activator --patch '{"spec":{"template":{"spec":{"affinity":{"nodeAffinity":{"requiredDuringSchedulingIgnoredDuringExecution":{"nodeSelectorTerms":[{"matchExpressions":[{"key":"kubernetes.io/hostname","operator":"In","values":["node1", "node3"]}]}]}}}}}}}'

#     # patch image
#     kubectl -n knative-serving patch deploy activator --patch '{"spec":{"template":{"spec":{"containers":[{"name":"activator","image":"docker.io/bonavadeur/ikukantai-activator:latest"}]}}}}'
#     kubectl -n knative-serving patch deploy net-kourier-controller --patch '{"spec":{"template":{"spec":{"containers":[{"name":"controller","image":"docker.io/bonavadeur/ikukantai-kourier:latest"}]}}}}'

#     # patch service
#     kubectl -n kourier-system patch service kourier --patch '{"spec":{"internalTrafficPolicy":"Local","externalTrafficPolicy":"Local"}}'
#     kubectl -n kourier-system patch service kourier-internal --patch '{"spec":{"internalTrafficPolicy":"Local"}}'
# }

proposal() {
    tag=$1

    # patch replicas
    kubectl -n kourier-system patch deploy 3scale-kourier-gateway --patch '{"spec":{"replicas":3}}'
    kubectl -n knative-serving patch deploy activator --patch '{"spec":{"replicas":2}}'

    # patch nodeSelector
    kubectl -n kourier-system patch deploy 3scale-kourier-gateway --patch '{"spec":{"template":{"spec":{"affinity":{"nodeAffinity":{"requiredDuringSchedulingIgnoredDuringExecution":{"nodeSelectorTerms":[{"matchExpressions":[{"key":"kubernetes.io/hostname","operator":"In","values":["node1", "node2", "node3"]}]}]}}}}}}}'
    kubectl -n knative-serving patch deploy activator --patch '{"spec":{"template":{"spec":{"affinity":{"nodeAffinity":{"requiredDuringSchedulingIgnoredDuringExecution":{"nodeSelectorTerms":[{"matchExpressions":[{"key":"kubernetes.io/hostname","operator":"In","values":["node1", "node3"]}]}]}}}}}}}'

    # patch image
    kubectl -n knative-serving patch deploy activator --patch '{"spec":{"template":{"spec":{"containers":[{"name":"activator","image":"docker.io/bonavadeur/ikukantai-activator:'$tag'"}]}}}}'
    kubectl -n knative-serving patch deploy controller --patch '{"spec":{"template":{"spec":{"containers":[{"name":"controller","image":"docker.io/bonavadeur/ikukantai-controller:'$tag'"}]}}}}'
    kubectl -n knative-serving patch deploy autoscaler --patch '{"spec":{"template":{"spec":{"containers":[{"name":"autoscaler","image":"docker.io/bonavadeur/ikukantai-autoscaler:'$tag'"}]}}}}'
    kubectl -n knative-serving patch deploy net-kourier-controller --patch '{"spec":{"template":{"spec":{"containers":[{"name":"controller","image":"docker.io/bonavadeur/ikukantai-kourier:'$tag'"}]}}}}'
    if [ $tag != "dev" ]; then
        kubectl -n knative-serving patch deploy activator --patch '{"spec":{"template":{"spec":{"containers":[{"name":"activator","imagePullPolicy": "Always"}]}}}}'
        kubectl -n knative-serving patch deploy net-kourier-controller --patch '{"spec":{"template":{"spec":{"containers":[{"name":"controller","imagePullPolicy": "Always"}]}}}}'
    elif [ $tag == "dev" ]; then
        kubectl -n knative-serving patch deploy activator --patch '{"spec":{"template":{"spec":{"containers":[{"name":"activator","imagePullPolicy": "IfNotPresent"}]}}}}'
        kubectl -n knative-serving patch deploy net-kourier-controller --patch '{"spec":{"template":{"spec":{"containers":[{"name":"controller","imagePullPolicy": "IfNotPresent"}]}}}}'
    fi

    # patch service
    kubectl -n kourier-system patch service kourier --patch '{"spec":{"internalTrafficPolicy":"Local","externalTrafficPolicy":"Local"}}'
    kubectl -n kourier-system patch service kourier-internal --patch '{"spec":{"internalTrafficPolicy":"Local"}}'
}

if [ $2 != "" ];
then
    $1 $2
else
    $1
fi
