# Ingress via Heptio Contour

Based on: [https://github.com/heptio/contour](https://github.com/heptio/contour)

## Installation

The installation is adapted be compliant with the `*-system` namespace convention for system plugins / helpers in this kubernetes cluster.

- Get deployment manifest and remove namespace defintion (gsed is GNU version of sed. Use `sed` on linux, and on Mac install via `brew`)

        curl -sL  https://j.hept.io/contour-deployment-rbac | \
        gsed -e '/^kind.*Namespace/,+4d' > contour-deployment-rbac.yaml

- Create patches to add namespace again

        cat <<EOF > namespace.yaml
        apiVersion: v1
        kind: Namespace
        metadata:
        name: contour-system
        EOF

        cat <<EOF > kustomization.yaml
        namespace: contour-system
        resources:
        - namespace.yaml
        - contour-deployment-rbac.yaml
        EOF

- Install patched `contour`

        kustomize build . | kubectl apply -f -

- Get Load Balancer external IP

        k8s-lb.sh -n contour-system contour
        # 192.168.124.231


## Test

- Deploy test artefacts (based on the [voyager example](https://github.com/appscode/voyager/tree/master/docs/examples/ingress/types/loadbalancer))

        kubectl run nginx --image=nginx
        kubectl expose deployment nginx --name=web --port=80 --target-port=80

        kubectl run echoserver --image=gcr.io/google_containers/echoserver:1.4
        kubectl expose deployment echoserver --name=rest --port=80 --target-port=8080

        kubectl get pods --watch
        kubectl get svc

        kubectl get ingress.voyager.appscode.com  # fully qualified !

- Define an ingress manifest

        cat <<EOF > ingress.yaml
        apiVersion: extensions/v1beta1
        kind: Ingress
        metadata:
          name: test-app
          labels:
            app: test-app
        spec:
          rules:
          - http:
              paths:
              - path: /web
                backend:
                  serviceName: web
                  servicePort: 80
              - path: /api
                backend:
                  serviceName: rest
                  servicePort: 80
        EOF

- Deploy

        kubectl apply -f ingress.yaml


- Call `web` endpoint and get nginx 404

        curl $(k8s-lb.sh -n contour-system contour)/web

        # <html>
        # <head><title>404 Not Found</title></head>
        # <body>
        # <center><h1>404 Not Found</h1></center>
        # <hr><center>nginx/1.15.5</center>
        # </body>
        # </html>

- Call `rest` endpoint

        curl $(k8s-lb.sh -n contour-system contour)/api

        # LIENT VALUES:
        # client_address=10.244.5.13
        # command=GET
        # real path=/api
        # query=nil
        # request_version=1.1
        # request_uri=http://192.168.124.231:8080/api
        # ...

- Clean up

        kubectl delete svc web rest
        kubectl delete deploy echoserver nginx
        kubectl delete ingress test-app


## Remove Contour

    kubectl delete ns contour-system
    kubectl delete clusterrole contour
    kubectl delete clusterrolebinding contour
    kubectl delete crd ingressroutes.contour.heptio.com
