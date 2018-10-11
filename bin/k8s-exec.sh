#!/bin/bash

function usage {
    echo "Usage:"
    echo "$(basename $0) [-s|-d|-n namespace] [-i <number>] <service> [<cmd>]"
    exit 1
}

# Defaults:
NAMESPACE=default
NUM=1

while getopts "sdn:i:" o; do
    case $o in
        d)
            NAMESPACE=default
            ;;
        s)
            NAMESPACE=kube-system
            ;;
        i)
            NUM="${OPTARG}"
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
NAME=$1
shift

if [[ "$1" == "" ]]; then
    CMD=sh
else
    CMD=$@
fi

POD=$(kubectl -n $NAMESPACE get po | awk "/^$NAME/ {print \$1}" | head -$NUM | tail +$NUM)
echo "Executing '$CMD' on pod '$POD' ($NUM)"

kubectl exec -n $NAMESPACE -it $POD $CMD
