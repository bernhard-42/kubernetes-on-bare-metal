## Install Rook with ceph
    
    - Clean up if necessary
        On each node:

        $ sudo rm -fr /usr/libexec/kubernetes/kubelet-plugins/volume/exec/*
        $ sudo rm -fr /var/lib/rook

    - Install ceph agents and discovery via helm

        $ helm repo add rook-beta https://charts.rook.io/beta
        $ helm install --namespace rook-ceph-system \
                       --name rook-ceph \
                       --set agent.flexVolumeDirPath=/usr/libexec/kubernetes/kubelet-plugins/volume/exec/ \
                       rook-beta/rook-ceph
        $ watch -n 2 kubectl --namespace rook-ceph-system get pods -l "app=rook-ceph-operator"

    - Create ceph cluster

        $ kubectl create -f ceph-cluster.yaml
        $ watch -n 2 kubectl -n rook-ceph get pod

    - Expose Dashboard 

        $ kubectl apply -f ceph-expose-dashboard.yaml
        $ kubectl -n rook-ceph get service | grep rook-ceph-mgr-dashboard-external

    - Create Storage class for kubernetes

        $ kubectl apply -f ceph-storage-class.yaml

    - Install Rook Toolbox

        $ kubectl apply -f rook-toolbox.yaml
    
    - Access Rook toolbox

        $ kubectl -n rook-ceph exec -it rook-ceph-tools bash






sudo dd if=/dev/zero of=/opt/sdv1-backstore bs=1G count=50
sudo mknod /dev/fake-sdv1 b 7 200
sudo losetup /dev/fake-sdv1 /opt/sdv1-backstore

helm serve &
helm repo add local http://localhost:8879/charts
git clone https://github.com/ceph/ceph-helm
cd ceph-helm/ceph
make

kubectl create namespace ceph
kubectl create -f rbac.yaml
kubectl label node beebox02 ceph-mon=enabled ceph-mgr=enabled
for i in $(seq 3 6); do kubectl label node beebox0$i  ceph-osd=enabled ceph-osd-device-dev-sdv1=enabled ceph-osd-device-dev-sdv1=enabled; done


#  etcd
kubectl exec -n kube-system -it etcd-beebox01 /bin/sh
alias ec="ETCDCTL_API=3 etcdctl --endpoints=localhost:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/healthcheck-client.crt --key=/etc/kubernetes/pki/etcd/healthcheck-client.key"
ec memeber list

# debug iptables

iptables -A INPUT -m limit --limit 50/minute -j LOG --log-level 7 --log-prefix "Dropped in: "
iptables -A OUTPUT -m limit --limit 50/minute -j LOG --log-level 7 --log-prefix "Dropped out: "
iptables -A FORWARD -m limit --limit 50/minute -j LOG --log-level 7 --log-prefix "Dropped fw: "

iptables -D INPUT -m limit --limit 50/minute -j LOG --log-level 7 --log-prefix "Dropped in: "
iptables -D OUTPUT -m limit --limit 50/minute -j LOG --log-level 7 --log-prefix "Dropped out: "
iptables -D FORWARD -m limit --limit 50/minute -j LOG --log-level 7 --log-prefix "Dropped fw: "

tail -f /var/log/kerb.log | grep Dropped

