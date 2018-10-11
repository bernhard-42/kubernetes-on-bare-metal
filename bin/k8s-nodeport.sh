#!/bin/bash

function usage {
    echo "Usage:"
    echo "$(basename $0) [-n namespace] <service>"
    exit 1
}

# Defaults:
NAMESPACE=default

while getopts "sdn:i:" o; do
    case $o in
        d)
            NAMESPACE=default
            ;;
        s)
            NAMESPACE=kube-system
            ;;
        n)
            NAMESPACE="${OPTARG}"
            ;;
        *)
            usage
    esac
done
shift $((OPTIND-1))

[[ "$1" == "" ]] && usage

kubectl get svc $1 -n $NAMESPACE --template='{{(index .spec.ports 0).nodePort}}'
