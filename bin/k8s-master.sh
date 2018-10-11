#!/bin/bash

function usage {
    echo "Usage:"
    echo "$(basename $0) [-u]"
    exit 1
}

# Defaults:
GETURL=0

while getopts "u" o; do
    case $o in
        u)
            GETURL=1
            ;;
        *)
            usage
    esac
done
shift $((OPTIND-1))


SERVER=$(kubectl config view --template='{{(index .clusters 0).cluster.server }}') 
if [[ "$GETURL" -eq 1 ]]; then
    echo $SERVER
else
    echo $SERVER | sed 's|https://\(.*\):.*|\1|'
fi
