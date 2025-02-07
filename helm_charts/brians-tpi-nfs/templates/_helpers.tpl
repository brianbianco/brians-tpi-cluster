{{- $nfsProvisionerRelease := "nfs-subdir-external-provisioner" }}  # The release name from your HelmChart
{{- $namespace := "default" }}  # The target namespace for the provisioner

# Check if the HelmChart resource exists in the cluster to confirm that the NFS provisioner was installed
{{- if not (lookup "helm.cattle.io/v1" "HelmChart" $namespace $nfsProvisionerRelease) }}
  {{- fail "The required NFS provisioner HelmChart release is missing. Ensure the NFS provisioner HelmChart is installed first!" }}
{{- end }}

# Check if the ConfigMap required by the NFS provisioner exists
{{- if not (lookup "v1" "ConfigMap" $namespace "chart-content-nfs") }}
  {{- fail "The required NFS provisioner ConfigMap (chart-content-nfs) is missing. Ensure the NFS provisioner is installed and properly configured!" }}
{{- end }}

