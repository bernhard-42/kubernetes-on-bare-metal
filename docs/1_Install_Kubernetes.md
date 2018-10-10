# Kubernetes

Note: On a mac deactivate ipv6 [https://www.xgadget.de/anleitung/macos-ipv6-deaktivieren-am-mac/](https://www.xgadget.de/anleitung/macos-ipv6-deaktivieren-am-mac/)

    networksetup -setv6off Ethernet
    networksetup -setv6off Wi-Fi

Reason: kubeadm sets kube-proxy listenaddr to `0.0.0.0` instead of `::`.

Can be reactivated via 

    networksetup -setv6automatic Wi-Fi 
    networksetup -setv6automatic Ethernet


## Install kubernetes executables on each node

- Preparations

        sudo -i

        swapoff -a                                   # kubernetes does not run with swap
        sysctl net.bridge.bridge-nf-call-iptables=1  # necessary for overlay networks
        modprobe dm_thin_pool                        # needed for glusterfs

- Install kubernetes executables (as root)

    Note: For the time being (Oct 2018) use v1.11.3 instead of v1.12.x to avoid issues with flannel

        curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
        cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
        deb http://apt.kubernetes.io/ kubernetes-xenial main
        EOF
        apt-get update
        # apt-get install -y kubelet kubeadm kubectl
        apt-get install -y kubelet=1.11.3-00 kubeadm=1.11.3-00 kubectl=1.11.3-00
        apt-mark hold kubelet kubeadm kubectl

- Optional: Load all kubernetes images

        kubeadm config images pull


## Initialize kubernetes cluster on the admin node

- Initialize cluster (as root)
    
        kubeadm init --pod-network-cidr=10.244.0.0/16 # cidr range for Flannel and Canal

- Configure access for root (and non root) user

        rm -fr ~/.kube
        mkdir -p $HOME/.kube
        sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
        sudo chown $(id -u):$(id -g) $HOME/.kube/config


## Install network plugin flannel

- Install flannel on admin node

       kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

- Test kubernetes installation and check that `coredns` gets successfully instantiated

        kubectl get po --all-namespaces


## Join nodes

- Run the command that was provided by `kubeadm init` similar to the following on all nodes except master

        kubeadm join 192.168.124.145:6443 \
                --token 9iit70.9pm7eju8gouj5ay8 \
                --discovery-token-ca-cert-hash \
                sha256:f7ff34d89ae03c7c5df7b194a1f084d1dc39d4eacde4ccbe9251d739ccd21df3

- Check that all nodes are running

    kubectl get nodes


## Enable remote control

- On the local laptop 

        scp root@beebox01:/etc/kubernetes/admin.conf .
        rm -fr ~/.kube
        mkdir -p ~/.kube
        mv admin.conf ~/.kube/config

Note: From now on it is expected that kubectl commands get issued from the laptop (for remote kubernets cluster)

## Test kubernetes and networking

- Install kubernetes tutorial bootcamp app

        kubectl run kubernetes-bootcamp --image=gcr.io/google-samples/kubernetes-bootcamp:v1 --port=8080
        kubectl get deployments
        kubectl get po

- Run kubernetes proxy in another terminal on the laptop

        kubectl proxy

- Test installed app via local proxy

        export POD_NAME=$(kubectl get pods -o go-template --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
        echo Name of the Pod: $POD_NAME
        curl http://localhost:8001/api/v1/namespaces/default/pods/$POD_NAME/proxy/
    
- Expose app

        kubectl expose deployment/kubernetes-bootcamp --type="NodePort" --port 8080
        kubectl get services -o wide
        kubectl describe services/kubernetes-bootcamp

- Test via local proxy

        curl http://localhost:8001/api/v1/namespaces/default/services/http:kubernetes-bootcamp:/proxy/

- Test installed app via NodePort

        export NODE_PORT=$(kubectl get services/kubernetes-bootcamp -o go-template='{{(index .spec.ports 0).nodePort}}')
        echo NODE_PORT=$NODE_PORT
        curl beebox01:$NODE_PORT

- Cleanup

        kubectl delete deploy kubernetes-bootcamp
        kubectl delete svc kubernetes-bootcamp

