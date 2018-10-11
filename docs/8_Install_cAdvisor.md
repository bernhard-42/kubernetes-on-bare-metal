
# Install cAdvisor as Daemonset

## Install kustomize

    brew install kustomize

## Install cAdvisor

    mkdir cAdvisor
    cd cAdvisor/
    git clone https://github.com/google/cadvisor.git
    cd cadvisor/deploy/kubernetes/

## Deploy customized cAdvisor

- Prepare customization

        mkdir overlays/custom

- Define the two customization files

        cat <<EOF > overlays/custom/kustomization.yaml
        bases:
        - ../../base
        patches:
        - schedule-master.yaml
        - cadvisor-args.yaml
        EOF

- Add some parameters to cAdvisor to reduce load on local kube proxy

        cat <<EOF > overlays/custom/cadvisor-args.yaml
        apiVersion: apps/v1 # for Kubernetes versions before 1.9.0 use apps/v1beta2
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
                  - --disable_metrics=tcp,udp                # enable only diskIO, cpu, memory, network
                  - --docker_only=true                       # only show stats for docker containers
        EOF

- Allow deployment on master node

        cat <<EOF > overlays/custom/schedule-master.yaml
        apiVersion: apps/v1 # for Kubernetes versions before 1.9.0 use apps/v1beta2
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

- Deploy customized manifest

    kustomize build overlay/custom | kubectl apply -f -

## Open cAdvisor per node

    k82-cadvisor.sh node

