#!/bin/bash

function usage {
    echo "Usage:"
    echo "$(basename $0) [-s|-d|-n namespace] [-i <number>] <service> [<cmd>]"
    exit 1
}

# Defaults:
NAMESPACE=default
NUM=1
WHERE=b

while getopts "sdn:i:bec" o; do
    case $o in
        d) NAMESPACE=default ;;
        s) NAMESPACE=kube-system ;;
        i) NUM="${OPTARG}" ;;
        n) NAMESPACE="${OPTARG}" ;;
        b) WHERE=b ;;
        e) WHERE=e ;;
        c) WHERE=c ;;
         *) usage
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

POD=$(k8s-pod-name.sh -n $NAMESPACE -$WHERE $NAME | head -$NUM | tail +$NUM)
echo -e "\nExecuting '$CMD' on pod '$POD' ($NUM)\n"

kubectl exec -n $NAMESPACE -it $POD $CMD
