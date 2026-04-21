# Unity Catalog

Open source catalog supporting Iceberg, Delta Lake, and other formats. Exposes an Iceberg
REST catalog API for PySpark and DuckDB. Metadata in Postgres, table files on Longhorn PVC.

Note: Unity Catalog's helm chart does not support custom S3 endpoints, so Garage cannot
be used as the table file store. Spark reads/writes table data directly via its own S3A
connector — this limitation only affects tables created natively through Unity Catalog.

- UI: https://unitycatalog.brians.computer
- REST API: https://unitycatalog.brians.computer/api/2.1/unity-catalog

## Install

### 1. Create the Postgres database and user

Hibernate manages table creation automatically — only the database and user need to exist.

```bash
kubectl exec -n postgres -it postgres-1 -- psql -U postgres
```

```sql
CREATE USER unitycatalog WITH PASSWORD 'your-password';
CREATE DATABASE unitycatalog OWNER unitycatalog;
```

### 2. Create secrets

```bash
kubectl create namespace unitycatalog

kubectl create secret generic unitycatalog-postgres-secret --namespace unitycatalog --from-literal=username='unitycatalog' --from-literal=password='your-password'
```

### 3. Install

There is no published Helm repository — install directly from the GitHub source:

```bash
git clone --depth 1 https://github.com/unitycatalog/unitycatalog.git /tmp/unitycatalog

helm upgrade --install unitycatalog /tmp/unitycatalog/helm \
  --namespace unitycatalog \
  --create-namespace \
  --values values.yaml
```

**Ingress note:** The chart uses a single top-level `ingress` block for both the server
and UI on one hostname — path-based routing sends `/` to the UI and `/api` to the server.
There is no separate UI ingress. The correct field names are `ingressClassName` and
`tlsSecretName` (not `className` / `tls.secretName`).

## Using from JupyterHub notebooks

### PySpark

```python
from pyspark.sql import SparkSession

spark = (
    SparkSession.builder.remote(os.environ["SPARK_CONNECT_URL"])
    .config("spark.jars.packages", "org.apache.iceberg:iceberg-spark-runtime-3.5_2.13:1.7.0")
    .config("spark.sql.extensions", "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions")
    .config("spark.sql.catalog.unity", "org.apache.iceberg.spark.SparkCatalog")
    .config("spark.sql.catalog.unity.type", "rest")
    .config("spark.sql.catalog.unity.uri", "http://unitycatalog.unitycatalog.svc.cluster.local:8080/api/2.1/unity-catalog/iceberg")
    .getOrCreate()
)
```

### DuckDB

```python
import duckdb

con = duckdb.connect()
con.execute("INSTALL iceberg; LOAD iceberg;")
con.execute("""
    CREATE SECRET unity_catalog (
        TYPE S3,
        ENDPOINT 'garage.garage.svc.cluster.local:3900',
        USE_SSL false
    )
""")
