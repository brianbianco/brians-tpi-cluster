# Ollama

Ollama serves local LLM inference via an OpenAI-compatible REST API. One release runs in
the `ollama` namespace, pinned to magus (rk1):

| Release | Model | Node | Ingress | Values file |
|---|---|---|---|---|
| `ollama-general` | qwen3:8b | magus (rk1) | https://ollama-general.brians.computer | values-general.yaml |

The API is open (no auth). The DNS entry resolves to an internal IP behind NAT — not
publicly reachable.

## Storage

Uses `local-path` (k3s built-in, 20Gi) because magus is the cluster controller and
Longhorn block storage is intentionally disabled on that node.

## Add the Helm repo

```bash
helm repo add ollama-helm https://otwld.github.io/ollama-helm/
helm repo update
```

## Create namespace

```bash
kubectl create namespace ollama
```

## Install

```bash
helm upgrade --install ollama-general ollama-helm/ollama \
  --namespace ollama \
  -f values-general.yaml
```

## Monitor model pull

The chart pulls `qwen3:8b` (~5.2GB) at startup via a PostStart lifecycle hook. Takes
several minutes on first deploy.

```bash
kubectl logs -n ollama deploy/ollama-general -f
```

Wait until you see the Gin HTTP server start line before the pod is considered ready.

## Pulling models manually

```bash
kubectl exec -n ollama deploy/ollama-general -- ollama pull qwen3:8b
```

## Monitoring

Ollama v0.23.x does not expose a Prometheus metrics endpoint. The ServiceMonitor in
`manifests/servicemonitor-ollama.yaml` is commented out. If a future Ollama version adds
metrics support, uncomment that file, re-apply it, and search https://grafana.com/grafana/dashboards
for "Ollama" to find a community dashboard.

## Connecting from JupyterHub

Use the in-cluster service URL with the OpenAI-compatible client. The `api_key` value
is ignored by Ollama but required by the OpenAI SDK:

```python
from openai import OpenAI

ollama = OpenAI(
    base_url="http://ollama-general.ollama.svc.cluster.local:11434/v1",
    api_key="ollama",
)

response = ollama.chat.completions.create(
    model="qwen3:8b",
    messages=[{"role": "user", "content": "Write a Python hello world"}],
)
print(response.choices[0].message.content)
```
