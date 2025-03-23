# MetalLB install

You first have to install the base chart

```
helm repo add metallb https://metallb.github.io/metallb
helm repo update
helm upgrade --install metallb metallb/metallb --namespace metallb-system --create-namespace --wait
```

helm upgrade --install metallb-config ./ --namespace metallb-system -f values.yaml
