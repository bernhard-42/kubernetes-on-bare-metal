kubectl -n kube-system delete deploy kubernetes-dashboard
kubectl -n kube-system delete svc kubernetes-dashboard
kubectl -n kube-system delete sa kubernetes-dashboard
kubectl -n kube-system delete roles kubernetes-dashboard-minimal
kubectl -n kube-system delete rolebinding kubernetes-dashboard-minimal
