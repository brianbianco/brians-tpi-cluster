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


## Traefik compatibility notes

The operator generates nginx-style Ingress resources. Three extra pieces are needed since this cluster uses Traefik:

**spark-middleware.yaml** — `StripPrefixRegex` middleware that strips `/job/<appname>` before forwarding to Spark. Nginx does this via its rewrite annotation, which Traefik ignores. Without it, Spark receives the full path and infinite-redirect-loops.

**spark-tls-cert.yaml** — Standalone cert-manager `Certificate` for `spark.brians.computer`. Ingress-shim-managed certs are owned by the Ingress and deleted with it — since Spark creates a new Ingress per job, that would hit Let's Encrypt rate limits.

**Annotations in spark-operator-values.yaml** — `router.pathmatcher: PathRegexp` because the operator's regex paths would otherwise be treated as literal strings; `router.entrypoints: web,websecure` because Spark generates `http://` redirect URLs regardless of the incoming scheme — without the HTTP entrypoint those redirects 404.
