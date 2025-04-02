# Install the helm chart

```
helm repo add community-charts https://community-charts.github.io/helm-charts
helm repo update
```

```
kubectl create namespace mlflow
```


```
kubectl create secret generic mlflow-s3-secret --namespace=mlflow --from-literal=AWS_ACCESS_KEY_ID=minio --from-literal=AWS_SECRET_ACCESS_KEY=miniosecret --from-literal=MLFLOW_S3_ENDPOINT_URL=http://minio.default.svc.cluster.local:9000
```

```
kubectl create secret generic mlflow-postgres-secret --namespace=mlflow --from-literal=username=mlflowuser --from-literal=password=mlflowpassword
```

```
helm upgrade --install mlflow community-charts/mlflow --namespace mlflow -f values.yaml
```
