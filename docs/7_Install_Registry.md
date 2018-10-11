# Docker registry

## Install docker registry with helm

Notes:

- This is an insecure registry sufficient for my dev environment.
- Provide 10GB of persitent storage in storage class `gluster-heketi` for the images:

Installation

    CONFIG=\
    persistence.enabled=true,\
    persistence.storageClass=gluster-heketi,\
    persistence.size=10Gi,\
    service.type=LoadBalancer

    helm install --name registry --set $CONFIG stable/docker-registry


## Enable insecure registry for *Docker for Mac*

Retrive the loadbalancer IP (e.g. REG_IP=192.168.124.230) and add `REG_IP:5000` to `Daemon` Preferences. The  restart *Docker for Mac*

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

            docker build --force-rm -t $REG_IP:5000/alpine-enhanced:1.0.0 .

            docker images
            #  REPOSITORY                             TAG      IMAGE ID      CREATED        SIZE
            #  192.168.124.230:5000/alpine-enhanced   1.0.0    6437ee14582e  7 seconds ago  46.8MB
            #  alpine                                 latest   196d12cf6ab1  4 weeks ago    4.41MB

    - Push image to registry

            docker push $REG_IP:5000/alpine-enhanced:1.0.0

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

    - Access container

            kubectl exec -it alpine-enhanced bash
