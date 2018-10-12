# Kubernetes

## Install kubernetes executables on each node

- Install kubernetes executables (as root)

    Note: For the time being (Oct 2018) use v1.11.3 instead of v1.12.x to avoid issues with flannel

        sudo -i

        curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
        cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
        deb http://apt.kubernetes.io/ kubernetes-xenial main
        EOF
        apt-get update
        apt-get install -y kubelet kubeadm kubectl
        # apt-get install -y kubelet=1.11.3-00 kubeadm=1.11.3-00 kubectl=1.11.3-00
        apt-mark hold kubelet kubeadm kubectl

- Optional: Load all kubernetes images

        kubeadm config images pull


## Initialize kubernetes cluster on the admin node

- Initialize cluster (as root with cidr range for Flannel and Canal)
    
        kubeadm init --pod-network-cidr=10.244.0.0/16

- Configure access for root (and non root) user

        rm -fr ~/.kube
        mkdir -p $HOME/.kube
        sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
        sudo chown $(id -u):$(id -g) $HOME/.kube/config


## Install network plugin flannel

- Install canal on admin node

    This provides an CNI overlay network by `flannel` and network policies by `calico`

        BASE_URL=https://docs.projectcalico.org/v3.2/getting-started/kubernetes/
        kubectl apply -f $BASE_URL/installation/hosted/canal/rbac.yaml
        kubectl apply -f $BASE_URL/installation/hosted/canal/canal.yaml

    Note: For a "flannel only" deployment use the master version from github (until 0.11): 
    
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

    kubectl get nodes --watch


## Enable remote control

- On the local laptop 

        scp root@beebox01:/etc/kubernetes/admin.conf .
        rm -fr ~/.kube
        mkdir -p ~/.kube
        mv admin.conf ~/.kube/config

Note: From now on it is expected that kubectl commands get issued from the laptop (for remote kubernets cluster)


## Test kubernetes and networking

- Install kubernetes tutorial bootcamp app

        for i in 0 1; do 
            kubectl run kubernetes-bootcamp$i --image=gcr.io/google-samples/kubernetes-bootcamp:v1 --port=8080
        done
        kubectl get po --watch

- Run kubernetes proxy in **another** terminal on the laptop (blocking command)

        kubectl proxy

- Test installed app via local proxy (ensure to have ./bin in the PATH to access the local k82 helpers)

        for i in 0 1; do
            curl http://localhost:8001/api/v1/namespaces/default/pods/$(k8s-pod-name.sh -c bootcamp$i)/proxy/
        done
    
- Expose app

        for i in 0 1; do
            kubectl expose deployment/kubernetes-bootcamp$i --type="NodePort" --port 8080
            kubectl describe services/kubernetes-bootcamp$i
            echo -e "\nNodeport for bootcamp0: $(k8s-nodeport.sh -e bootcamp$i)\n"
        done

- Test via local proxy

        for i in 0 1; do
            curl http://localhost:8001/api/v1/namespaces/default/services/http:kubernetes-bootcamp$i:/proxy/
        done

- Test installed app via NodePort

        for i in 0 1; do
            curl -v beebox01:$(k8s-nodeport.sh -e bootcamp$i)
        done

- Test of DNS and cross container networking

    Enter pod kubernetes-bootcamp0

        k8s-exec.sh -c bootcamp0

        Executing 'sh' on pod 'kubernetes-bootcamp0-7775b6ccc7-lpx5h' (1)
        # 

    Curl the other pod kubernetes-bootcamp1

        curl kubernetes-bootcamp1.default.svc.cluster.local:8080
        exit

- Cleanup

        for i in 0 1; do
            kubectl delete deploy kubernetes-bootcamp$i
            kubectl delete svc kubernetes-bootcamp$i
        done

