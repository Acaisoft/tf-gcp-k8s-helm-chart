# Parameters authorized:
# version (default: v2.13.0)
# release_name (mandatory)
# chart_name (mandatory)
# chart_version (mandatory)
# namespace (mandatory)
# values (default: values.yaml)
# secret_values (default: secret-values.yaml)
variable "helm" {
  type        = "map"
  description = "Helm provider parameters"
  default     = {}
}

# Parameters authorized:
# project (mandatory)
# region (mandatory)
variable "provider" {
  type        = "map"
  description = "Google provider parameters"
}

# Parameters authorized:
# bucket (mandatory)
# prefix (mandatory)
variable "gke_cluster_remote_state" {
  type        = "map"
  description = "GKE cluster remote state parameters"
}

# Parameters authorized:
# name - secret name (default: app-secrets)
# data_file - file name for file with secret data content (default: app-secrets.data)
# type - secret type (default: Opaque)
variable "secrets" {
  type        = "list"
  description = "Kubernetes secrets to create"
  default     = []
}

# Parameters authorized:
# name - secret name (default: app-secrets)
# data_file - file name for file with config map data content (default: app-config-map.data)
variable "config_maps" {
  type        = "list"
  description = "Kubernetes config maps to create"
  default     = []
}