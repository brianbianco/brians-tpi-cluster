# Open WebUI

ChatGPT-style web interface for local LLM inference. Available at https://chat.brians.computer.

Connects to both Ollama instances and lets you pick which model to chat with. Requires
both Ollama releases to be running first (see `../ollama/README.md`).

Open WebUI also runs a Redis sidecar for caching and session management — this is
included automatically by the chart.

## TLS

The ingress uses the `cert-manager.io/cluster-issuer` annotation, so cert-manager's
ingress-shim creates the `open-webui-tls` secret automatically. No standalone
`Certificate` resource is needed (unlike Spark, which requires one).

## Add the Helm repo

```bash
helm repo add open-webui https://helm.openwebui.com/
helm repo update
```

## Create namespace

```bash
kubectl create namespace open-webui
```

## Install

```bash
helm upgrade --install open-webui open-webui/open-webui \
  --namespace open-webui \
  -f values.yaml
```

## First login

Open WebUI creates the admin account on first signup — whoever registers first becomes
admin. Do this immediately after deploying. There is no invite-only mode by default, so
register before anyone else can.

## Ollama connection

The `values.yaml` points to the single Ollama instance via its cluster-internal URL:

```
http://ollama-general.ollama.svc.cluster.local:11434
```

The chart's bundled Ollama is disabled (`ollama.enabled: false`) — the external instance
is used instead.
