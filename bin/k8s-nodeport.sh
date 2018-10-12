#!/bin/bash

function usage {
    echo "Usage:"
    echo "$(basename $0) [-n namespace] [-bec] <service>"
    exit 1
}

# Defaults:
NAMESPACE=default
WHERE=b

while getopts "sdn:i:bec" o; do
    case $o in
        d) NAMESPACE=default ;;
        s) NAMESPACE=kube-system ;;
        n) NAMESPACE="${OPTARG}" ;;
        b) WHERE=b ;;
        e) WHERE=e ;;
        c) WHERE=c ;;
        *) usage
    esac
done
shift $((OPTIND-1))

[[ "$1" == "" ]] && usage

case $WHERE in
    b) SEARCH="^$1"   ;;
    e) SEARCH="$1\$"  ;;
    c) SEARCH="$1"    ;;
esac

kubectl -n $NAMESPACE get svc -o json | jq -r '.items[] | select(.metadata.name | test('\"$SEARCH\"')) | .spec.ports[].nodePort'
