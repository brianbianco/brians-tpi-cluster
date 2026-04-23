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

# Direct S3 access from notebooks

Every notebook pod automatically receives Garage S3 credentials via environment variables
injected from the `jupyter-s3-credentials` secret. Create this secret before installing:

```bash
# Create the dedicated jupyter key in Garage first
/garage key create jupyter
/garage bucket allow --read --write --owner misc --key <jupyter-key-id>
/garage bucket allow --read --write --owner iceberg --key <jupyter-key-id>

kubectl create secret generic jupyter-s3-credentials \
  --namespace jupyterhub \
  --from-literal=AWS_ACCESS_KEY_ID=<jupyter-key-id> \
  --from-literal=AWS_SECRET_ACCESS_KEY=<jupyter-secret-key>
```

The following env vars are pre-configured in every notebook pod:
- `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` — the `jupyter` Garage key
- `AWS_ENDPOINT_URL_S3` — points to Garage's internal cluster address
- `AWS_REGION` — set to `us-east-1` (required by AWS SDK, ignored by Garage)

This means `boto3` and `pyiceberg` work without any extra configuration:

```python
import boto3
s3 = boto3.client('s3')
s3.list_buckets()  # lists misc, iceberg

import pyiceberg.catalog
# pyiceberg can connect to the Polaris REST catalog directly
```

