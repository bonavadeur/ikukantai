#!/bin/bash

namespace=$1
grepName=$2

pods=($(kubectl get pod -n $namespace | grep $grepName | grep Running | awk '{print $1}'))

for i in "${!pods[@]}"
do 
  kubectl -n $namespace delete pod "${pods[$i]}"
done
