#!/bin/bash

function usage {
    echo "Usage:"
    echo "$(basename $0)"
    exit 1
}

cat << EOF

Usage:

alias ec="ETCDCTL_API=3 etcdctl --endpoints=localhost:2379 \
--cacert=/etc/kubernetes/pki/etcd/ca.crt \
--cert=/etc/kubernetes/pki/etcd/healthcheck-client.crt \
--key=/etc/kubernetes/pki/etcd/healthcheck-client.key"

ec get --keys-only --prefix /
EOF

k8s-exec.sh -s etcd /bin/sh
