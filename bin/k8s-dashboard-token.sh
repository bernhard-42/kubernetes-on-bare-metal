#!/bin/bash

function usage {
    echo "Usage:"
    echo "$(basename $0)"
    exit 1
}

SECRET=$(kubectl -n kube-system get  sa kubernetes-dashboard -o jsonpath='{@.secrets[].name}')

kubectl -n kube-system describe secret $SECRET | grep "token:" | awk '{print $2}'
