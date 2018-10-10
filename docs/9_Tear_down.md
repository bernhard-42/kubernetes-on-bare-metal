# 9 Tear down

## 9.1 Dashboard

    kubectl -n kube-system delete deploy kubernetes-dashboard
    kubectl -n kube-system delete svc kubernetes-dashboard
    kubectl -n kube-system delete role kubernetes-dashboard-minimal
    kubectl -n kube-system delete rolebinding kubernetes-dashboard-minimal
    kubectl -n kube-system delete sa kubernetes-dashboard
    kubectl -n kube-system delete secrets kubernetes-dashboard-key-holder
    kubectl -n kube-system delete secrets kubernetes-dashboard-certs
    kubectl -n kube-system delete secrets kubernetes-dashboard-token-g6b7b  

## 9.2 Kubernetes cluster

Drain and delete all nodes

    for i in $(seq 1 6); do kubectl drain beebox0$i --delete-local-data --force --ignore-daemonsets; done
    for i in $(seq 1 6); do kubectl delete node beebox0$i; done

Clean up etcd on the master

    docker exec -it $(docker ps | grep etcd | grep -v pause | awk '{print $1}') sh

    alias ec="ETCDCTL_API=3 etcdctl --endpoints=localhost:2379 \
                                    --cacert=/etc/kubernetes/pki/etcd/ca.crt \
                                    --cert=/etc/kubernetes/pki/etcd/healthcheck-client.crt \
                                    --key=/etc/kubernetes/pki/etcd/healthcheck-client.key"
    ec del "" --prefix

Reset kubeadm on the master

    sudo kubeadm reset
    sudo rm -fr ~/.kube* /root/.kube*

On all nodes

    sudo docker rm -f $(docker ps -a | awk '{print $1}')
    sudo docker rmi -f $(docker images | awk '{print $3}')
    sudo apt-get purge kube*
    sudo rm -fr /etc/kubernetes /etc/cni /var/lib/etcd/ /var/lib/cni /var/lib/kubelet/ /var/lib/heketi/ /var/lib/calico/ 
    
    # Source: https://unix.stackexchange.com/questions/13755/how-to-reset-all-iptables-settings#13756
    # RESET DEFAULT POLICIES
    iptables -P INPUT ACCEPT
    iptables -P FORWARD ACCE^PT
    iptables -P OUTPUT ACCEPT
    iptables -t nat -P PREROUTING ACCEPT
    iptables -t nat -P POSTROUTING ACCEPT
    iptables -t nat -P OUTPUT ACCEPT
    iptables -t mangle -P PREROUTING ACCEPT
    iptables -t mangle -P OUTPUT ACCEPT

    # FLUSH ALL RULES, ERASE NON-DEFAULT CHAINS
    iptables -F
    iptables -X
    iptables -t nat -F
    iptables -t nat -X
    iptables -t mangle -F
    iptables -t mangle -X

    sudo systemctl reboot
