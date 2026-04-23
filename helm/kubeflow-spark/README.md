## Kubeflow Spark Operator on k3s

This installs Spark Operator 2.5.0.
The driver UI for every job appears at:

https://spark.brians.computer/job/<appName>

## Add the Helm repo

```
helm repo add spark-operator https://kubeflow.github.io/spark-operator
helm repo update
```


## Apply supporting resources (do this first — Let's Encrypt takes a few minutes to issue)

```
kubectl create namespace spark
kubectl apply -f spark-tls-cert.yaml
kubectl apply -f spark-middleware.yaml

kubectl wait --for=condition=Ready certificate/spark-tls -n spark --timeout=300s
```


## Install the operator (uses spark-operator-values.yaml in this folder)

```
helm install spark-operator spark-operator/spark-operator --namespace spark --create-namespace --version 2.5.0 --wait -f spark-operator-values.yaml

kubectl -n spark get pods -l app.kubernetes.io/component=controller   # should show Running
```

## Submit the example job (spark-pi.yaml is in this folder)

```
kubectl apply -f spark-pi.yaml
watch -n1 kubectl -A get sparkapplications spark-pi
```


## Open the Spark UI while the job is running or for ten minutes after it finishes

```
https://spark.brians.computer/job/spark-pi
```


## Check job status

```
kubectl -n spark get sparkapplications spark-pi
```


## SparkConnect — interactive PySpark from JupyterHub

`spark-connect.yaml` deploys a persistent SparkConnect server in the `spark` namespace.
SparkConnect runs a long-lived Spark driver pod that JupyterHub notebooks connect to as
thin clients over port 15002. Executors spin up dynamically on the cluster nodes as needed
and are torn down when idle.

This is different from `SparkApplication` (batch jobs like spark-pi): SparkConnect is
interactive and session-based, designed for exploratory work in notebooks rather than
fire-and-forget jobs.

### Deploy the SparkConnect server

Create the Garage S3 credentials secret first — the SparkConnect server and its executor
pods use it for Iceberg table access via S3A. Credentials are injected as
`AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` env vars so they stay out of the YAML.
Batch `SparkApplication` jobs do not get these credentials; they would need their own
S3 setup if they require object storage access.

Use the dedicated `spark` Garage key (not the `jupyter` or `brian` key). Create it in
Garage first if it doesn't exist:

```bash
# In a garage pod
/garage key create spark
/garage bucket allow --read --write --owner warehouse --key <spark-key-id>
```

Then create the Kubernetes secret:

```bash
kubectl create secret generic spark-s3-credentials \
  --namespace spark \
  --from-literal=AWS_ACCESS_KEY_ID=<spark-key-id> \
  --from-literal=AWS_SECRET_ACCESS_KEY=<spark-secret-key>
```

Then deploy:

```bash
kubectl apply -f spark-connect.yaml
kubectl get sparkconnect spark-connect -n spark  # should show Ready
```

### Implementation notes

- `apache/spark:4.1.1` does not bundle the SparkConnect jars — they are fetched at startup
  via `spark.jars.packages`. The Ivy cache is redirected to `/tmp/.ivy2` since the spark
  user's home directory does not exist in the image.
- The operator creates the server pod using the `default` service account rather than
  `spark-operator-spark`. A RoleBinding (`spark-default-sa-spark-role`) is included in
  `spark-connect.yaml` to grant the necessary pod/service permissions to `default`.
- Iceberg (`iceberg-spark-runtime-4.0_2.13`) and Hadoop AWS (`hadoop-aws`) jars are
  included in `spark.jars.packages` along with the Iceberg Spark extensions, so notebooks
  can work with Iceberg tables and the Garage S3A connector out of the box. Static configs
  like `spark.sql.extensions` cannot be set by notebook clients — they must live in the
  server's `sparkConf`.

## Traefik compatibility notes

The operator generates nginx-style Ingress resources. Three extra pieces are needed since this cluster uses Traefik:

**spark-middleware.yaml** — `StripPrefixRegex` middleware that strips `/job/<appname>` before forwarding to Spark. Nginx does this via its rewrite annotation, which Traefik ignores. Without it, Spark receives the full path and infinite-redirect-loops.

**spark-tls-cert.yaml** — Standalone cert-manager `Certificate` for `spark.brians.computer`. Ingress-shim-managed certs are owned by the Ingress and deleted with it — since Spark creates a new Ingress per job, that would hit Let's Encrypt rate limits.

**Annotations in spark-operator-values.yaml** — `router.pathmatcher: PathRegexp` because the operator's regex paths would otherwise be treated as literal strings; `router.entrypoints: web,websecure` because Spark generates `http://` redirect URLs regardless of the incoming scheme — without the HTTP entrypoint those redirects 404.
