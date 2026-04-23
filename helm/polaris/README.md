# Apache Polaris — Iceberg REST Catalog

Apache Polaris is the reference implementation of the Iceberg REST catalog spec.
It provides full Iceberg table lifecycle management (create, drop, alter) via a REST API
that Spark can talk to natively as `spark.sql.catalog.*`.

API root: https://polaris.brians.computer (REST only — no web UI)
- Catalog API: `/api/catalog/v1/...`
- Management API: `/api/management/v1/...`

## Storage layout

All Iceberg tables use the base location `s3://polaris/iceberg/`. Table data lands
in two Garage buckets because Polaris 1.4.0 and Spark parse that URI differently:

| Service | Sees `s3://polaris/iceberg/...` as | Writes to Garage bucket |
|---------|-------------------------------------|-------------------------|
| Polaris | host=`polaris` (ignored), bucket=`iceberg` | `iceberg` |
| Spark   | bucket=`polaris`, path=`iceberg/...` | `polaris` |

In practice: Polaris writes small Iceberg metadata JSON files to `iceberg`; Spark writes
all data and manifest files to `polaris`. They never need to read each other's files
directly — they communicate table metadata through the REST API, not through shared S3
reads — so the mismatch doesn't cause problems.

The base location `s3://polaris/iceberg/` was chosen deliberately to exploit this
difference, ensuring each service writes to a bucket it has credentials for.


## Add the Helm repo

```bash
helm repo add polaris https://downloads.apache.org/incubator/polaris/helm-chart
helm repo update
```


## Create namespace

```bash
kubectl create namespace polaris
```


## Create the Garage S3 credentials

Polaris needs its own dedicated Garage access key scoped to the `iceberg` bucket.
Do not reuse the `jupyter` key — each service gets its own key.

```bash
# Create a dedicated key for Polaris
kubectl exec -n garage garage-0 -- /garage key create polaris
# Note the Key ID and Secret key from the output

# Grant it read/write/owner access to the iceberg bucket
kubectl exec -n garage garage-0 -- /garage bucket allow --read --write --owner iceberg --key <key-id>
```

Then create the Kubernetes secret:

```bash
kubectl create secret generic polaris-s3-credentials \
  --namespace polaris \
  --from-literal=AWS_ACCESS_KEY_ID=<key-id> \
  --from-literal=AWS_SECRET_ACCESS_KEY=<secret-key>
```

### Create the two storage buckets

Create both `iceberg` (Polaris metadata writes) and `polaris` (Spark data writes) if they don't exist:

```bash
kubectl exec -n garage garage-0 -- /garage bucket create iceberg
kubectl exec -n garage garage-0 -- /garage bucket allow --read --write --owner iceberg --key <polaris-key-id>

kubectl exec -n garage garage-0 -- /garage bucket create polaris
kubectl exec -n garage garage-0 -- /garage bucket allow --read --write --owner polaris --key <spark-key-id>
```

See `garage/README.md` for the full key/bucket access matrix.


## CoreDNS rewrite rule (required for S3 virtual-hosted style)

Polaris's AWS SDK uses virtual-hosted style S3 URLs (`http://<bucket>.<endpoint>/`).
Since Garage runs at a cluster-internal hostname, the SDK constructs URLs like
`http://iceberg.garage.garage.svc.cluster.local:3900/` which CoreDNS cannot resolve by default.

A CoreDNS rewrite rule is required to redirect any subdomain of the Garage service back
to the Garage service itself. This is a one-time cluster setup:

```bash
kubectl create configmap coredns-custom \
  --namespace kube-system \
  --from-literal='garage-s3.override=rewrite stop name regex (.+)\.garage\.garage\.svc\.cluster\.local garage.garage.svc.cluster.local answer auto'
kubectl rollout restart deployment/coredns -n kube-system
```

This rule is stored in the `coredns-custom` ConfigMap which k3s's CoreDNS imports
automatically from `/etc/coredns/custom/*.override`.


## Create the Postgres credentials secret

Polaris needs a Postgres database for persistence. Create the database and user first:

```bash
kubectl exec -n postgres -it postgres-1 -- psql -U postgres -c "CREATE USER polaris WITH PASSWORD '<password>';"
kubectl exec -n postgres -it postgres-1 -- psql -U postgres -c "CREATE DATABASE polaris OWNER polaris;"
```

Then create the secret:

```bash
kubectl create secret generic polaris-db-secret \
  --namespace polaris \
  --from-literal=username=polaris \
  --from-literal=password=<password> \
  --from-literal=jdbcUrl=jdbc:postgresql://postgres-rw.postgres.svc.cluster.local:5432/polaris
```


## Install Polaris

```bash
helm upgrade --install polaris polaris/polaris \
  --namespace polaris \
  --devel \
  --values values.yaml
kubectl wait --namespace polaris --for=condition=ready pod --selector=app.kubernetes.io/name=polaris --timeout=120s
```


## Bootstrap the catalog

This one-time step creates the initial realm, catalog, and root principal.
The `-c POLARIS,root,pass` argument sets the catalog name, root username, and password —
change `pass` to something real before running.

Run without `-it` so the output is captured in pod logs:

```bash
kubectl run polaris-bootstrap \
  -n polaris \
  --image=apache/polaris-admin-tool:latest \
  --restart=Never \
  --env="quarkus.datasource.username=$(kubectl get secret polaris-db-secret -n polaris -o jsonpath='{.data.username}' | base64 --decode)" \
  --env="quarkus.datasource.password=$(kubectl get secret polaris-db-secret -n polaris -o jsonpath='{.data.password}' | base64 --decode)" \
  --env="quarkus.datasource.jdbc.url=$(kubectl get secret polaris-db-secret -n polaris -o jsonpath='{.data.jdbcUrl}' | base64 --decode)" \
  -- \
  bootstrap -r POLARIS -c POLARIS,root,pass -p
kubectl wait pod/polaris-bootstrap -n polaris --for=jsonpath='{.status.phase}'=Succeeded --timeout=60s
kubectl logs polaris-bootstrap -n polaris
kubectl delete pod polaris-bootstrap -n polaris
```

The bootstrap output will show the root principal credentials. The `client_id` is `root`
and the `client_secret` is the password you set (`pass` above). Authenticate using OAuth2
client credentials with `client_id:client_secret`.

Once you have confirmed the credentials work, store them in a Kubernetes secret in the
`spark` namespace so SparkConnect can use them:

```bash
kubectl create secret generic polaris-credentials \
  --namespace spark \
  --from-literal=client_id=root \
  --from-literal=client_secret=<pass> \
  --from-literal=credential=root:<pass>
```


## Create the POLARIS catalog via Management API

After bootstrap, create the actual Iceberg catalog. The `default-base-location` must be
`s3://polaris/iceberg/` — see the Storage layout section above for why this specific
value is required.

```bash
TOKEN=$(curl -s -X POST https://polaris.brians.computer/api/catalog/v1/oauth/tokens \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials&client_id=root&client_secret=<pass>&scope=PRINCIPAL_ROLE:ALL" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['access_token'])")

curl -s -X PUT https://polaris.brians.computer/api/management/v1/catalogs/POLARIS \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "INTERNAL",
    "name": "POLARIS",
    "properties": {
      "default-base-location": "s3://polaris/iceberg/",
      "s3.checksum-enabled": "false"
    },
    "storageConfigInfo": {
      "storageType": "S3",
      "pathStyleAccess": true,
      "allowedLocations": ["s3://polaris/iceberg/"]
    }
  }'
```

Then grant the `catalog_admin` role to `service_admin`:

```bash
# Create catalog role
curl -s -X POST https://polaris.brians.computer/api/management/v1/catalogs/POLARIS/catalogRoles \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name": "catalog_admin"}'

# Grant CATALOG_MANAGE_CONTENT
curl -s -X PUT https://polaris.brians.computer/api/management/v1/catalogs/POLARIS/catalogRoles/catalog_admin/grants \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"type": "catalog", "privilege": "CATALOG_MANAGE_CONTENT"}'

# Assign to service_admin principal role
curl -s -X PUT https://polaris.brians.computer/api/management/v1/principal-roles/service_admin/catalog-roles/POLARIS \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name": "catalog_admin"}'
```


## Connect Spark to Polaris

The `spark-connect.yaml` in `helm/kubeflow-spark/` is already configured. Key settings:

```yaml
sparkConf:
  spark.sql.catalog.polaris: "org.apache.iceberg.spark.SparkCatalog"
  spark.sql.catalog.polaris.type: "rest"
  spark.sql.catalog.polaris.uri: "http://polaris.polaris.svc.cluster.local:8181/api/catalog"
  spark.sql.catalog.polaris.credential: "<client_id>:<client_secret>"
  spark.sql.catalog.polaris.warehouse: "POLARIS"
  spark.sql.catalog.polaris.scope: "PRINCIPAL_ROLE:ALL"
  # Iceberg S3FileIO properties for the polaris catalog
  spark.sql.catalog.polaris.s3.endpoint: "http://garage.garage.svc.cluster.local:3900"
  spark.sql.catalog.polaris.s3.region: "garage"
  spark.sql.catalog.polaris.s3.path-style-access: "true"
```

Both server and executor containers also have `AWS_REGION=garage` and
`AWS_ENDPOINT_URL_S3=http://garage.garage.svc.cluster.local:3900` set directly
in their pod templates. This is required because the Iceberg S3FileIO's
`DefaultAwsClientFactory` falls back to `DefaultAwsRegionProviderChain` on executors.

Then from a notebook:

```python
import os
from pyspark.sql import SparkSession

spark = SparkSession.builder.remote(os.environ["SPARK_CONNECT_URL"]).getOrCreate()

spark.sql("CREATE NAMESPACE IF NOT EXISTS polaris.my_namespace")
spark.sql("""
  CREATE TABLE IF NOT EXISTS polaris.my_namespace.my_table (
    id BIGINT,
    name STRING
  ) USING iceberg
""")
spark.sql("INSERT INTO polaris.my_namespace.my_table VALUES (1, 'hello')")
spark.sql("SELECT * FROM polaris.my_namespace.my_table").show()
```
