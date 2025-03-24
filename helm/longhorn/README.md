# Installing longhorn


```
helm dependency build
helm upgrade --install longhorn-install . --namespace longhorn-system --create-namespace --wait
```

# disabling local-path as default storage class

To disable local-path as the default storage class to avoid ambiguity if a storage class isn't defined

```
kubectl annotate storageclass local-path storageclass.kubernetes.io/is-default-class-
```
