terraform {
  # The configuration for this backend will be filled in by Terragrunt
  backend "gcs" {}
}

data "terraform_remote_state" "gke_cluster" {
  backend = "gcs"
  config {
    bucket  = "${var.gke_cluster_remote_state["bucket"]}"
    prefix  = "${var.gke_cluster_remote_state["prefix"]}"
  }
}

data "google_client_config" "current" {}

provider "google" {
  region      = "${var.provider["region"]}"
  project     = "${var.provider["project"]}"
}

provider "kubernetes" {
  load_config_file = false

  host                   = "${data.terraform_remote_state.gke_cluster.endpoint}"
  token                  = "${data.google_client_config.current.access_token}"
  cluster_ca_certificate = "${base64decode(data.terraform_remote_state.gke_cluster.cluster_ca_certificate)}"
}

provider "helm" {
  tiller_image = "gcr.io/kubernetes-helm/tiller:${lookup(var.helm, "version", "v2.13.0")}"

  install_tiller = true
  service_account = "${data.terraform_remote_state.gke_cluster.tiller_service_account}"
  namespace = "kube-system"

  kubernetes {
    host                   = "${data.terraform_remote_state.gke_cluster.endpoint}"
    token                  = "${data.google_client_config.current.access_token}"
    cluster_ca_certificate = "${base64decode(data.terraform_remote_state.gke_cluster.cluster_ca_certificate)}"
  }
}

data "external" "secret_data_json" {
  count = "${length(var.secrets)}"
  program = ["/bin/cat", "${lookup(var.secrets[count.index], "data_file", "app-secrets-secret.json")}"]
}

data "external" "config_map_data_json" {
  count = "${length(var.config_maps)}"
  program = ["/bin/cat", "${lookup(var.config_maps[count.index], "data_file", "app-config-map.json")}"]
}

resource "kubernetes_secret" "app_secret" {
  count = "${length(var.secrets)}"
  metadata {
    name      = "${lookup(var.secrets[count.index], "name", "app-secrets")}"
    namespace = "${var.helm["namespace"]}"
  }
  data = "${data.external.secret_data_json.*.result[count.index]}"
  type = "${lookup(var.secrets[count.index], "type", "Opaque")}"

  depends_on = ["helm_release.chart_release"]
}

resource "kubernetes_config_map" "app_config_map" {
  count = "${length(var.config_maps)}"
  metadata {
    name      = "${lookup(var.config_maps[count.index], "name", "app-config-map")}"
    namespace = "${var.helm["namespace"]}"
    labels    = "${var.config_maps_labels[count.index]}"
  }
  data = "${data.external.config_map_data_json.*.result[count.index]}"
  
  depends_on = ["helm_release.chart_release"]
}


resource "helm_release" "chart_release" {
  name      = "${var.helm["release_name"]}"
  chart     = "${var.helm["chart_name"]}"
  version   = "${var.helm["chart_version"]}"
  namespace = "${var.helm["namespace"]}"
  values = [
    "${file(lookup(var.helm, "values", "values.yaml"))}",
    "${file(lookup(var.helm, "secret_values", "secret-values.yaml"))}"
  ]
}