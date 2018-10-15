# Helm with RBAC

- Create a service account

        kubectl apply -f helm/helm-rbac-config.yaml

- Install and initialize helm

        brew install kubernetes-helm
        helm init --service-account tiller

## Test helm

- Install e.g. tomcat

        helm install --name my-release stable/tomcat
        kubectl get po --watch
        helm list

- Clean up

        helm delete --purge my-release

[<== Install Kubernetes Dashboard](./2_Install_Kubernetes_Dashboard.md) | [Install Storage Provider ==>](./4_Install_Storage_Provider.md)
