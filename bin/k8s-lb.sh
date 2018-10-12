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

kubectl -n $NAMESPACE get svc -o json | jq -r '.items[] | select(.metadata.name | test('\"$SEARCH\"')) | .status.loadBalancer.ingress[].ip'




exit 0
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

# kubectl get svc $1 -n $NAMESPACE --template='{{(index (index .status.loadBalancer.ingress) 0).ip}}'
kubectl get svc -n $NAMESPACE | awk '/^'$1/' {print $4}'