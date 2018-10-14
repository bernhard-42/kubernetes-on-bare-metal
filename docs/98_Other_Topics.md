# Other topics

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


## Persistent storage Provider via Ceph and Rook

### Installation

- Install Operator

        helm repo add rook-beta https://charts.rook.io/beta
        helm install --name rook-ceph --namespace rook-ceph-system rook-beta/rook-ceph

        kubectl -n rook-ceph-system get pod --watch

- Check rook-ceph version

        helm list
        NAME       	REVISION	UPDATED                 	STATUS  	CHART            ...
        moldy-zebra	1       	Sun Oct 14 12:38:55 2018	DEPLOYED	rook-ceph-v0.8.3 ...

- Install Cluster

        mkdir ceph
        cd ceph

        git clone https://github.com/rook/rook.git
        cd rook/

- Checkout the correct version

        git checkout tags/v0.8.3 -b v0.8.3

- Optional: Clean all cluster nodes

        sudo rm -fr /var/lib/rook

- Install Cluster

        cd cluster/examples/kubernetes/ceph
        kubectl create -f cluster.yaml

- Add Storage Class

        cat <<EOF > storageclass.yaml
        apiVersion: ceph.rook.io/v1beta1
        kind: Pool
        metadata:
          name: replicapool
          namespace: rook-ceph
        spec:
          replicated:
            size: 3
        ---
        apiVersion: storage.k8s.io/v1
        kind: StorageClass
        metadata:
           name: rook-ceph-block
        provisioner: ceph.rook.io/block
        parameters:
          pool: replicapool
          clusterNamespace: rook-ceph
        EOF

        kubectl create -f storageclass.yaml


- Add Loadbalancer to Ceph Dashboard

        cat << EOF > dashboard-external.yaml
        apiVersion: v1
        kind: Service
        metadata:
          name: rook-ceph-mgr-dashboard-external
          namespace: rook-ceph
          labels:
            app: rook-ceph-mgr
            rook_cluster: rook-ceph
        spec:
          ports:
          - name: dashboard
            port: 7000
            protocol: TCP
            targetPort: 7000
          selector:
            app: rook-ceph-mgr
            rook_cluster: rook-ceph
          sessionAffinity: None
          type: LoadBalancer
        EOF

        kubectl apply -f dashboard-external.yaml

### Clean up

- Delete Cluster

        kubectl delete ns rook-ceph

- Delete Operator

        helm delete --purge rook-ceph
        kubectl delete ns rook-ceph-system

