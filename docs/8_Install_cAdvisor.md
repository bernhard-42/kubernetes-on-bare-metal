
# Install cAdvisor as Daemonset

## Install cAdvisor

    mkdir cAdvisor
    cd cAdvisor/
    git clone https://github.com/google/cadvisor.git
    

## Deploy customized cAdvisor

- Prepare customization

        cp cadvisor/deploy/kubernetes/base/daemonset.yaml .

- Define the namespace manifest

        cat <<EOF > namespace.yaml
        apiVersion: v1
        kind: Namespace
        metadata:
          name: cadvisor-system
        EOF

- Add some parameters to cAdvisor to reduce load on local kube proxy

        cat <<EOF > cadvisor-args.yaml
        apiVersion: apps/v1
        kind: DaemonSet
        metadata:
          name: cadvisor
        spec:
          template:
            spec:
              containers:
              - name: cadvisor
                args:
                  - --housekeeping_interval=5s
                  - --max_housekeeping_interval=10s
                  - --event_storage_event_limit=default=0
                  - --event_storage_age_limit=default=0
                  - --disable_metrics=tcp,udp
                  - --docker_only=true
        EOF

- Allow deployment on master node

        cat <<EOF >schedule-master.yaml
        apiVersion: apps/v1
        kind: DaemonSet
        metadata:
          name: cadvisor
        spec:
          template:
            spec:
             tolerations:
                - key: node-role.kubernetes.io/master
                  effect: NoSchedule
        EOF


- Expose cAdvisor on each node on port 9999

        cat <<EOF > hostport.yaml
        apiVersion: apps/v1
        kind: DaemonSet
        metadata:
          name: cadvisor
        spec:
          template:
            spec:
              containers:
              - name: cadvisor
                ports:
                - name: http
                  containerPort: 8080
                  hostPort: 9999
                  protocol: TCP
        EOF

- Define the customization file

        cat <<EOF > kustomization.yaml
        namespace: cadvisor-system
        commonLabels:
          app: cadvisor
        resources:
        - daemonset.yaml
        - namespace.yaml
        patches:
        - schedule-master.yaml
        - cadvisor-args.yaml
        - hostport.yaml
        EOF

- Deploy customized manifest

        kustomize build . | kubectl apply -f -


## Open cAdvisor per node

    open http://beebox01:9999
