# Kubernetes Dashboard

## Installation

- Installation without certificates

        kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml

- Create Service Account role binding

        kubectl -n kube-system create clusterrolebinding kubernetes-dashboard \
                --clusterrole=cluster-admin \
                --serviceaccount=kube-system:kubernetes-dashboard

## Login with service account token

- Get token for service account

        k8s-dashboard-token.sh
        eyJh ...       <== THIS IS THE LOGIN TOKEN

- Dashboard browser URL:

    http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/#!/cluster
