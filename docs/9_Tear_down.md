# Tear down

## Kubernetes cluster

Note: In order to be able to completely reset iptables, docker will also be uninstalled!

- Drain and delete all nodes

        for i in $(seq 1 6); do
            kubectl drain beebox0$i --delete-local-data --force --ignore-daemonsets;
            kubectl delete node beebox0$i;
        done

- Clean up etcd on the master

        docker exec -it $(docker ps | grep etcd | grep -v pause | awk '{print $1}') sh

        ETCDCTL_API=3 etcdctl --endpoints=localhost:2379 \
                              --cacert=/etc/kubernetes/pki/etcd/ca.crt \
                              --cert=/etc/kubernetes/pki/etcd/healthcheck-client.crt \
                              --key=/etc/kubernetes/pki/etcd/healthcheck-client.key \
                      del "" --prefix

- Reset kubeadm on the master

        sudo kubeadm reset
        sudo rm -fr ~/.kube* /root/.kube*

- Uninstall docker and kubernetes on all nodes

        sudo docker rm -f $(docker ps -a | awk '{print $1}' | grep -v CONTAINER)
        sudo docker rmi -f $(docker images | awk '{print $3}' | grep -v CONTAINER)
        sudo apt-get purge 'kube*' docker-ce
        sudo rm -fr /etc/kubernetes /var/lib/kubelet/ /var/lib/etcd/ \
                    /etc/cni /var/lib/cni /run/flannel /var/lib/calico/\
                    /var/lib/heketi/ \
                    /var/lib/docker /var/lib/dockershim

- Reset iptables (ipv4)

    Source: [https://unix.stackexchange.com/questions/13755/how-to-reset-all-iptables-settings#13756](https://unix.stackexchange.com/questions/13755/how-to-reset-all-iptables-settings#13756)

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

- Remove network devices

    Source: [https://stackoverflow.com/questions/46276796/kubenetes-cannot-cleanup-flannel/](https://stackoverflow.com/questions/46276796/kubenetes-cannot-cleanup-flannel/)

        for i in cni0 docker0; do
            ifconfig $i down;
            brctl delbr $i;
        done
        ifconfig flannel.1 down
        ip link delete flannel.1

- Reboot system

        sudo systemctl reboot
