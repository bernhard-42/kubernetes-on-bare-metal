#!/bin/bash

function usage {
    echo "Usage:"
    echo "$(basename $0) <node>"
    exit 1
}

[[ "$1" == "" ]] && usage

POD=$(kubectl -n cadvisor get po -o wide | awk "/$1/"'{print $1}')
echo "cAdvisor pod on node '$1' is $POD"

open http://localhost:8001/api/v1/namespaces/cadvisor/pods/$POD/proxy/containers/
