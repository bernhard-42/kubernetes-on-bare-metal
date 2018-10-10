#!/bin/bash

function k8susage {
    echo "Usage:"
    echo "k8s [-n namespace] nodeport <service>"
    echo "k8s master"
}


# Command line arguments

function k8s_nodeport {
    echo $(kubectl get svc $1 -n $2 --template='{{(index .spec.ports 0).nodePort}}')
}

function k8s_lb {
    echo $(kubectl get svc $1 -n $2 --template='{{(index (index .status.loadBalancer.ingress) 0).ip}}')
}

function k8s {
    local OPTIND

    # Defaults:
    NAMESPACE=default

    while getopts "n:" o; do
        case $o in
            n)
                NAMESPACE="${OPTARG}"
                shift 2
                ;;
            *)
                k8s_usage
        esac
    done

    cmd="$1"
    shift

    case "$cmd" in
        nodeport)
            k8s_nodeport $1 $NAMESPACE
            ;;
        lb)
            k8s_lb $1 $NAMESPACE
            ;;
        master)
            echo "$(kubectl config view --template='{{(index .clusters 0).cluster.server }}' | sed 's|https://\(.*\):.*|\1|')"
            ;;
        *)
            k8susage
    esac
}