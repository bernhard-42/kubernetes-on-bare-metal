# Bare metal Kubernetes Playground

This is the writeup of building a playground of Kubernetes 1.12.1 on 6 bare metal machines.

The setup was built in order to understand Kubernetes and its ecosystem. It is **not** meant as a blueprint for production. There is no HA involved (even not for etcd), many components are not secured via TLS (e.g. the registry), proper monitoring is missing (e.g. no Prometheus), ...

However it enables importaant Kubernetes features on bare metal including

- Network Policies
- Persistent Storage Provider
- Load Balancer
- Ingress Controller

and to deploy apps as if it would be kubernetes on a cloud provider.


## Machine Setup

The cluster is built on 6 machines (6 x *ASRock beebox* boxes with 16 GB memory and 4 cores running Ubuntu 16.04). The beeboxes are nice playgroud machines due to their silence and low power consumption while providing sufficient computing power especially for efficient apps and frameworks like Kubernetes (e.g. the java based hadoop framework did not run too well)

Cluster

- Master: beebox01
- Nodes: beebox02, ..., beebox06

Developer Machine:

- Mac laptop

## Setup Documentation

To make it easier to see which component belongs to which of the plugins / helpers, the setup uses namespaces.

### Prepare Developer laptop and beeboxes

==> [docs/0_Preparation.md](docs/0_Preparation.md)

### Install Kubernetes and overlay network

- Kubernetes is set up via [kubeadm](https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm/)
- [canal](https://docs.projectcalico.org/v3.2/getting-started/kubernetes/installation/flannel) was selected as CNI network plugin to provide an overlay network via *flannel* and network policies via *calico*.
- Namespace: `kube-system`

==> [docs/1_Install_Kubernetes.md](docs/1_Install_Kubernetes.md)

### Install Kubernetes Dashboard

- The [Kubernetes Dashboard](https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/) helps especially at the beginning to get an overview of what is deployed and where
- Namespace: `kube-system`

==> [docs/2_Install_Kubernetes_Dashboard.md](docs/2_Install_Kubernetes_Dashboard.md)

### Install Helm Package Manager

- The [Helm package manager](https://www.helm.sh/) will be used to install some of the plugins and helpers
- Namespace: `kube-system`

==> [docs/3_Install_Helm.md](docs/3_Install_Helm.md)

### Install Persistent Storage Provider for *StatefulSets*

- The Persistent Storage provider is based on [GlusterFS](https://www.gluster.org/) integrated into Kubernetes via [heketi](https://github.com/heketi/heketi)
- Namespace: `gluster-system`

==> [docs/4_Install_Storage_Provider.md](docs/4_Install_Storage_Provider.md)

### Install a Load Balancer

- The Load Balancer for kubernetes uses [metallb](https://metallb.universe.tf/) in Layer 2 mode. A range of IP addresses in the own subnet are required.
- Namespace: `metallb-system`

==> [docs/5_Install_Load_Balancer.md](docs/5_Install_Load_Balancer.md)

### Install an Ingress Controller

- There is a great overview in [https://kubedex.com/nginx-ingress-vs-kong-vs-traefik-vs-haproxy-vs-voyager-vs-contour-vs-ambassador/](https://kubedex.com/nginx-ingress-vs-kong-vs-traefik-vs-haproxy-vs-voyager-vs-contour-vs-ambassador/) as a starting point.
- Moved away from [Voyager](https://appscode.com/products/voyager/) since it does not support the Kubernetes Ingress Object. This might break ootb helm charts that use Ingress.
- [Heptio Contour](https://github.com/heptio/contour) is used as Ingress Controller, supporting both Ingress Object and an own IngressRoute API
- Namespace: `heptio-contour`

==> [docs/6_Install_Ingress_controller.md](docs/6_Install_Ingress_controller.md)


### Install the Docker Registry

- The aim is to build docker containers on the Mac laptop with docker for Mac, push them to the private registry and deploy then afterwards with kubernetes.
- The easiest way here was to use the private [Docker registry](https://docs.docker.com/registry/).
- Namespace: `registry-system`

==> [docs/7_Install_Registry.md](docs/7_Install_Registry.md)

### Install Simple Container Monitoring

- Simple monitoring of each node with [cAdvisor](https://github.com/google/cadvisor).
- Namespace: `cadvisor-system`

==> [docs/8_Install_cAdvisor.md](docs/8_Install_cAdvisor.md).

Note: This is also an example of using [kustomize](https://kustomize.io/) to adapt manifests with changing the original files.

## Cleanup

While VMs can just be rebuilt after a non successful attempt to install kubernetes with all its plugins and helpers, bare metal boxes need to be cleaned. This involves executables, persisted configurations, run time information, iptables rules, network devices, ... .

==> [docs/9_Tear_down.md](docs/9_Tear_down.md)
