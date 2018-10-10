# 3 Helm with RBAC

    - Create a service account

        $ kubectl apply -f helm-rbac-config.yaml

    - Install and initialize helm

        $ brew install kubernetes-helm
        $ helm init --service-account tiller


