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

# Using PySpark from notebooks

The cluster runs a SparkConnect server (see `helm/kubeflow-spark/README.md`). The
`SPARK_CONNECT_URL` environment variable is automatically injected into every user
server, so connecting is straightforward:

```python
import os
from pyspark.sql import SparkSession

spark = SparkSession.builder.remote(os.environ["SPARK_CONNECT_URL"]).getOrCreate()
```

From there the full PySpark DataFrame API is available. Spark executors spin up on the
cluster automatically when you run your first job and are released when idle.

The notebook image includes `pyspark[connect]` which provides both the PySpark library
and the gRPC client dependencies required by SparkConnect.

