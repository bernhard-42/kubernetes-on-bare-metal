# Helpers

## Inspect etcd

    kubectl exec -n kube-system -it etcd-beebox01 /bin/sh
    alias ec="ETCDCTL_API=3 etcdctl --endpoints=localhost:2379 \
                                    --cacert=/etc/kubernetes/pki/etcd/ca.crt \
                                    --cert=/etc/kubernetes/pki/etcd/healthcheck-client.crt \
                                    --key=/etc/kubernetes/pki/etcd/healthcheck-client.key"
    ec member list

## Debug iptables

- Turn tracing of dropped packages on

        iptables -A INPUT -m limit --limit 50/minute -j LOG --log-level 7 --log-prefix "Dropped in: "
        iptables -A OUTPUT -m limit --limit 50/minute -j LOG --log-level 7 --log-prefix "Dropped out: "
        iptables -A FORWARD -m limit --limit 50/minute -j LOG --log-level 7 --log-prefix "Dropped fw: "

- Inspect trace

        tail -f /var/log/kerb.log | grep Dropped

- Turn tracing of dropped packages off

        iptables -D INPUT -m limit --limit 50/minute -j LOG --log-level 7 --log-prefix "Dropped in: "
        iptables -D OUTPUT -m limit --limit 50/minute -j LOG --log-level 7 --log-prefix "Dropped out: "
        iptables -D FORWARD -m limit --limit 50/minute -j LOG --log-level 7 --log-prefix "Dropped fw: "
