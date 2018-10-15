# Docker registry

## Install docker registry with helm

- Notes:
    - This is an insecure registry sufficient for my dev environment.
    - Provide 10GB of persitent storage in storage class `gluster-heketi` for the images:

- Installation

        kubectl create ns registry-system

        CONFIG=\
        persistence.enabled=true,\
        persistence.storageClass=gluster-heketi,\
        persistence.size=10Gi,\
        service.type=LoadBalancer

        helm install --name registry --set $CONFIG \
                     --namespace registry-system \
                     stable/docker-registry


## Enable insecure registry for *Docker for Mac*

Retrieve the loadbalancer IP 

    k8s-lb.sh -n registry-system registry

(e.g. 192.168.124.230) and add `192.168.124.230:5000` to `Daemon` Preferences. Then restart *Docker for Mac*


## Enable insecure registry on kubernetes nodes

On all nodes add '{ "insecure-registries" : [ "192.168.124.230:5000" ] }' to `/etc/docker/daemon.json` and restart docker 

    systemctl restart docker


## Test 

- On the Mac

    - Create image

            cat <<EOF > Dockerfile
            FROM alpine

            RUN apk add bash && \
                apk add curl && \
                apk add python

            CMD sleep 2147483648
            EOF

            docker build --force-rm -t 192.168.124.230:5000/alpine-enhanced:1.0.0 .

            docker images
            #  REPOSITORY                             TAG      IMAGE ID      CREATED        SIZE
            #  192.168.124.230:5000/alpine-enhanced   1.0.0    6437ee14582e  7 seconds ago  46.8MB
            #  alpine                                 latest   196d12cf6ab1  4 weeks ago    4.41MB

    - Push image to registry

            docker push 192.168.124.230:5000/alpine-enhanced:1.0.0

- On the kubernetes cluster

    - Create manifest

            cat <<EOF > alpine-enhanced.yaml
            apiVersion: v1
            kind: Pod
            metadata:
              name: alpine-enhanced
              labels:
                name: alpine-enhanced
            spec:
              containers:
              - image: $REG_IP:5000/alpine-enhanced:1.0.0
                command:
                  - sleep
                  - "2147483647"
                name: alpine-enhanced
            EOF

    - Apply manifest

            kubectl apply -f alpine-enhanced.yaml
            kubectl get po alpine-enhanced --watch

            kubectl describe po alpine-enhanced | grep Image
            #     Image:         192.168.124.230:5000/alpine-enhanced:1.0.0
            #     Image ID:      docker-pullable://192.168.124.230:5000/alpine-enhanced@sha256:77952 ...

    - Access container

            kubectl exec -it alpine-enhanced bash

    - Clean up

            kubectl delete po alpine-enhanced


[<== Install Ingress controller](./6_Install_Ingress_controller.md) | [Install cAdvisor ==>](./8_Install_cAdvisor.md)
