# Bare metal Kubernetes Playground

This is the writeup of building a playground of Kubernetes 1.12.1 on 6 bare metal machines.

The setup was built in order to understand Kubernetes and its ecosystem. It is **not** meant as a blueprint for production. There is no HA involved (even not for etcd), many components are not secured via TLS (e.g. the registry), proper monitoring is missing (e.g. no Prometheus), ...

However it allows all Kubernetes features on bare metal including

- Persistent Storage Provider
- Load Balancer
- Ingress

to deploy apps as if it would be on a cloud provider.

## Machine Setup

The cluster is built on 6 machines (6 x *ASRock beebox* with 16 GB memory and 4 cores running Ubuntu 16.04). The beeboxes are nice playgroud machines due to their silence and low power consumption while providing sufficient computing power especially for efficient apps and frameworks like Kubernetes (e.g. the java based hadoop framework did not run too well)

Cluster

- Master: beebox01
- Nodes: beebox02, ..., beebox06

Developer Machine.

- Mac laptop

### Preparation of the Mac

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

### Preparation of the beeboxes

- Kubernetes does not run with swap

        sudo swapoff -a

- Prepare for overlay networks

        sudo sysctl net.bridge.bridge-nf-call-iptables=1

- Prepare for glusterfs

        sudo modprobe dm_thin_pool

- Install docker-ce on all nodes

        sudo apt-get install docker-ce


## Setup Documentation

### Install Kubernetes and overlay netowrk

Kubernetes is set up via `kubeadm` and [flannel](https://github.com/coreos/flannel) was selected as CNI network plugin (mostly due to simplicity).

Note: Flannel does not support Network Policies

**TODO**: Use [canal]() instead of flannel

==> [docs/1_Install_Kubernetes.md](docs/1_Install_Kubernetes.md)

### Install Kubernetes Dashboard

The [Kubernetes Dashboard](https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/) helps especially at the beginning to get an overview of what is deployed and where

==> [docs/2_Install_Kubernetes_Dashboard.md](docs/2_Install_Kubernetes_Dashboard.md)
    
### Install Helm Package Manager
    
The [Helm package manager](https://www.helm.sh/) will be used to install some of the plugins and helpers

==> [docs/3_Install_Helm.md](docs/3_Install_Helm.md)

### Install Persistent Storage Provider

The Persistent Storage provider is based on [GlusterFS](https://www.gluster.org/) integrated into Kubernetes via [heketi](https://github.com/heketi/heketi)

==> [docs/4_Install_Storage_Provider.md](docs/4_Install_Storage_Provider.md)

### Install a Load Balancer

The Load Balancer for kubernetes uses [metallb](https://metallb.universe.tf/) in Layer 2 mode. A range of IP addresses in the own subnet are required.

==> [docs/5_Install_Load_Balancer.md](docs/5_Install_Load_Balancer.md)

### Install an Ingress Controller

[Voyager](https://appscode.com/products/voyager/) was selected as Ingress Controller. There is a great overview in [https://kubedex.com/nginx-ingress-vs-kong-vs-traefik-vs-haproxy-vs-voyager-vs-contour-vs-ambassador/](https://kubedex.com/nginx-ingress-vs-kong-vs-traefik-vs-haproxy-vs-voyager-vs-contour-vs-ambassador/) as a starting point.

While [Envoy](https://github.com/envoyproxy/envoy) is cool and as such all Envoy based ingress controllers (e.g. *ambassador*, *Countour*), Voyager is built on the battle proven [HAProxy](http://www.haproxy.org/), also supports dynamic discovery and supports out of the box *metallb* as load balancer. The latter made it a good choice because of using *metallb*.

Note, since Voyager uses CRDs the Voyager Ingress Controller are not shown in Kubernetes Dashboard.

==> [docs/6_Install_Ingress_controller.md](docs/6_Install_Ingress_controller.md)

### Install the Docker Registry

The aim is to build docker containers on the Mac laptop with docker for Mac, push them to the private registry and deploy then afterwards with kubernetes.

The easiest way here was to use the private [Docker registry](https://docs.docker.com/registry/). 

==> [docs/7_Install_Registry.md](docs/7_Install_Registry.md)

### Install Simple Container Monitoring

Simple monitoring of each node with [cAdvisor](https://github.com/google/cadvisor).

==> [docs/8_Install_cAdvisor.md](docs/8_Install_cAdvisor.md).


## Cleanup

While VMs can just be rebuilt after a non successful attempt to install kubernetes with all its plugins and helpers, bare metal boxes need to be cleaned. This involves executables, persisted configurations, run time information, iptables rules, network devices, ..., see [Tear down](docs/9_Tear_down.ms).
