
Create the root user and password secret

```
kubectl create namespace minio
kubectl create secret generic minio-creds --from-literal=rootUser=minioadmin --from-literal=rootPassword=thepassword --namespace minio
```


```
kubectl label node <node name> minio-preferred=true
kubectl get node <node name> --show-labels
kubectl describe node <node name> | grep Taint
```

```
helm repo add minio https://charts.min.io/ && helm repo update
helm install minio minio/minio --version 5.4.0 --namespace minio --create-namespace -f values.yaml
```
