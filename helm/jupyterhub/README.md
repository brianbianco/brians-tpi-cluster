# Add the JupyterHub repository

```
helm repo add jupyterhub https://hub.jupyter.org/helm-chart/
helm repo update
```

# Create namespace and secret

```
kubectl create namespace jupyterhub
kubectl create secret generic jupyterhub-secret --namespace jupyterhub --from-literal=dummy_password='the-password'
```

# Install JupyterHub

```
helm upgrade --install jupyterhub jupyterhub/jupyterhub --namespace jupyterhub --values values.yaml
```

