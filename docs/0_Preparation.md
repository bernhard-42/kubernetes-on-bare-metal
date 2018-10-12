# Preparation

## Preparation of the Mac

- It is always a good idea to have Homebrew installed ([https://brew.sh/](https://brew.sh/)). Tools like `kubectl`, `helm` and `kustomize` can be easily installed with it.
- For the tools in `./bin` we need json parser `jq`

        brew install jq

- On the Mac deactivate ipv6 (see [https://www.xgadget.de/anleitung/macos-ipv6-deaktivieren-am-mac/](https://www.xgadget.de/anleitung/macos-ipv6-deaktivieren-am-mac/))

        networksetup -setv6off Ethernet
        networksetup -setv6off Wi-Fi

    Reason: kubeadm sets kube-proxy `bindAddress` to `0.0.0.0` instead of `::` - and some Macs resolve host names as ipv6 addresses instead of ipv4 addresses

    This can be reactivated after kubernetes tests via 

        networksetup -setv6automatic Wi-Fi 
        networksetup -setv6automatic Ethernet

    **TODO**: Find a way to change kube-proxy bind address to `::` and test again

## Preparation of the beeboxes

- Kubernetes does not run with swap

        sudo swapoff -a

- Prepare for overlay networks

        sudo sysctl net.bridge.bridge-nf-call-iptables=1

- Prepare for glusterfs

        sudo modprobe dm_thin_pool

- Install docker-ce on all nodes

        sudo apt-get install docker-ce