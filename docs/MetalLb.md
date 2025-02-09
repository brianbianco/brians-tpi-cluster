## Download the install manifest
curl -O https://raw.githubusercontent.com/metallb/metallb/main/config/manifests/metallb-native.yaml

## Copy the install manifests to the install directory
cp metallb-native.yaml /var/lib/rancher/k3s/server/manifests/

## Wait a bit then check to see if the pods came alive.
kubectl get pods -n metallb-system

## See if traefik has an external IP
kubectl get svc -n kube-system traefik # This should now report an external IP
