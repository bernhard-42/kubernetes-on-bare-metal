# 5 Loadbalancer via metallb 0.7.3

Based on [https://metallb.universe.tf/tutorial/layer2/](https://metallb.universe.tf/tutorial/layer2/)

## 5.1 Get `metallb` repo

    cd metallb
    git clone https://github.com/google/metallb.git
    cd metallb/
    git checkout tags/v0.7.3 -b v0.7.3
    cd ..

    cp metallb/manifests/example-layer2-config.yaml layer2-config.yaml

## 5.2 Install MetalLB 

    kubectl apply -f metallb/manifests/metallb.yaml

## 5.3 Configure IP range

Edit IP ranges in `layer2-config.yaml` and apply
        
    kubectl apply -f layer2-config.yaml

## 5.4 Test LoadBalancer

    kubectl apply -f metallb/manifests/tutorial-2.yaml
    

