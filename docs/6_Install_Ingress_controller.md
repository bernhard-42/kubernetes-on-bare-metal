# Ingress via Voyager 8.0.1

Based on [https://appscode.com/products/voyager/8.0.1/setup/install/](https://appscode.com/products/voyager/8.0.1/setup/install/)

## Install Voyager

- Ceate namespace

        cd ingress
        kubectl create ns voyager-system

- Add Voyager helm repo

        helm repo add appscode https://charts.appscode.com/stable/
        helm repo update
        helm search appscode/voyager

- Install voyager

        helm install appscode/voyager --name voyager-operator --version 8.0.1 \
                                        --namespace voyager-system \
                                        --set cloudProvider=metallb

## Test Voyager
        
- Deploy test artefacts

        BASE_URL="https://raw.githubusercontent.com/appscode/voyager/8.0.1/docs/examples"
        curl -fsSL $BASE_URL/ingress/types/loadbalancer/deploy-servers.sh | bash
        kubectl apply -f $BASE_URL/ingress/types/loadbalancer/ing.yaml

        kubectl get pods,svc
        kubectl get ingress.voyager.appscode.com  # fully qualified !

- Call web endpoint

        curl $(k8s-lb.sh -c voyager-test-ingress)  -H "Host: web.example.com"

- Call rest endpoint

        curl $(k8s-lb.sh -c voyager-test-ingress)  -H "Host: app.example.com"

- Clean up

        for s in voyager-test-ingress web rest; do kubectl delete svc $s; done
        for d in echoserver nginx voyager-test-ingress; do kubectl delete deploy $d; done
        kubectl delete ingress.voyager.appscode.com test-ingress