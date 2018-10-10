# 4 Persistent Storage Provider via Glusterfs and Heketi 8.0.0 

Based on [https://github.com/heketi/heketi/blob/master/docs/admin/install-kubernetes.md](https://github.com/heketi/heketi/blob/master/docs/admin/install-kubernetes.md)

## 4.1 Prepare file based devices

    sudo fallocate -l 50G /opt/sdv1.store
    sudo mknod /dev/fake-sdv1 b 7 200 # 200 should be high enough for a free loop### device
    sudo losetup /dev/fake-sdv1 /opt/sdv1.store

## 4.2 Install heketi-cli

    wget https://github.com/heketi/heketi/releases/download/v8.0.0/heketi-client-v8.0.0.darwin.amd64.tar.gz
    tar -ztvf heketi-client-v8.0.0.darwin.amd64.tar.gz
    PATH=$PATH:"$(pwd)/heketi-client/bin"

## 4.3 Install Heketiand Glusterfs

- Get git repo

        cd gluster
        git clone https://github.com/heketi/heketi.git
        cd heketi/
        git checkout tags/v8.0.0 -b v8.0.0
        cd ..

        cp heketi/extras/kubernetes/heketi.json .
        cp heketi/extras/kubernetes/topology-sample.json topology.json

- Install Glusterfs 

        kubectl create -f heketi/extras/kubernetes/glusterfs-daemonset.json
        kubectl label node beebox02 beebox03 beebox04 beebox05 beebox06 storagenode=glusterfs

- Check until all glusterfs nodes are running

      kubectl get pods -o wide

- Create service account

        kubectl create -f heketi/extras/kubernetes/heketi-service-account.json
        kubectl create clusterrolebinding heketi-gluster-admin \
                --clusterrole=edit \
                --serviceaccount=default:heketi-service-account

- Create a Kubernetes secret that will hold the configuration of our Heketi instance (edit keys before)

        kubectl create secret generic heketi-config-secret --from-file=./heketi.json

- Deploy initial pod

        kubectl create -f heketi/extras/kubernetes/heketi-bootstrap.json

- Check until pod is running

       kubectl get pods -o wide

- Forward heketi-cli port in separate terminal

        kubectl port-forward $(kubectl get po | awk '/heketi/ {print $1}') 8080:8080
        curl localhost:8080/hello

- Prepare topology.json

        cat topology.json

        {
          "clusters": [
            {
              "nodes": [
                {
                  "node": {
                    "hostnames": { "manage": [ "beebox02" ], "storage": [ "192.168.10.146" ] },
                    "zone": 1
                  },
                  "devices": [
                    { "name": "/dev/fake-sdv1", "destroydata": true }
                  ]
                },
                {
                  "node": {
                    "hostnames": { "manage": [ "beebox03" ], "storage": [ "192.168.10.147" ] },
                    "zone": 1
                  },
                  "devices": [
                    { "name": "/dev/fake-sdv1", "destroydata": true }
                  ]
                },
                {
                  "node": {
                    "hostnames": { "manage": [ "beebox04" ], "storage": [ "192.168.10.148" ] },
                    "zone": 1
                  },
                  "devices": [
                    { "name": "/dev/fake-sdv1", "destroydata": true }
                  ]
                },
                {
                  "node": {
                    "hostnames": { "manage": [ "beebox05" ], "storage": [ "192.168.10.149" ] },
                    "zone": 1
                  },
                  "devices": [
                    { "name": "/dev/fake-sdv1", "destroydata": true }
                  ]
                },
                {
                  "node": {
                    "hostnames": { "manage": [ "beebox06" ], "storage": [ "192.168.10.150" ] },
                    "zone": 1
                  },
                  "devices": [
                    { "name": "/dev/fake-sdv1", "destroydata": true }
                  ]
                }
              ]
            }
          ]
        }

        heketi-cli topology load --json=topology.json

- Set up a volume for heketi in glusterfs

        heketi-client/bin/heketi-cli setup-openshift-heketi-storage
        kubectl create -f heketi-storage.json

- Wait until job is finished

        kubectl get jobs

- Delete bootstrap heketi

        kubectl delete all,service,jobs,deployment,secret --selector="deploy-heketi"

- Create final heketi

        kubectl create -f heketi/extras/kubernetes/heketi-deployment.json 

- Optional: Expose via NodePort

        kubectl get svc heketi -o yaml | sed 's/type:.*$/type: NodePort/g' | kubectl replace -f -
        export HEKETI_CLI_SERVER="http://beebox01:$(kubectl get svc heketi --template='{{(index .spec.ports 0).nodePort}}')"
        heketi-cli volume list


## Create Gluster Storage Class

- Define a storage class

        cat gluster-storageclass.yaml
        
        apiVersion: storage.k8s.io/v1beta1
        kind: StorageClass
        metadata:
          name: gluster-heketi
        provisioner: kubernetes.io/glusterfs
        parameters:
          resturl: "http://10.105.71.42:8080"
          restuser: "admin"
          restuserkey: "sercret123"
     
    - For the `resturl` take the service's cluster IP
    - For `restuser` and `restuserkey` refer back to `heketi.json`

- and add it

        kubectl create -f gluster-storageclass.yaml

## Test Persistent Volume Claims

- Create PVC

        kubectl create -f pvc.yaml
        kubectl get pv,pvc

- Use PVC for nginx

        kubectl apply -f nginx.yaml

- Test

        NODE_PORT=$(kubectl get services/nginx -o go-template='{{(index .spec.ports 0).nodePort}}')
        curl beebox01:$NODE_PORT

- Edit `index.html`

        kubectl exec -ti nginx-pod1 /bin/sh
        cd /usr/share/nginx/html
        echo 'Hello World from GlusterFS!!!' > index.html
        exit

- Destroy nginx

        kubectl delete svc nginx
        kubectl delete po nginx-pod1

- Test again

        kubectl apply -f nginx.yaml
        NODE_PORT=$(kubectl get services/nginx -o go-template='{{(index .spec.ports 0).nodePort}}')
        curl beebox01:$NODE_PORT


