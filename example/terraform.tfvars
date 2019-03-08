terragrunt = {
  dependencies {
    paths = ["../4-flux"]
  }

  terraform {
    source = "git::git@github.com:Acaisoft/tf-gcp-k8s-helm-chart.git?ref=v0.1.0"
  }
  
  remote_state {
    backend = "gcs"
    config {
      bucket  = "tf-acai-bolt"
      prefix  = "dev/helm-chart/state"
    }
  }

  # Include all settings from the root terraform.tfvars file
  include = {
    path = "${find_in_parent_folders()}"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These are the variables we have to pass in to use the module specified in the terragrunt configuration above
# ---------------------------------------------------------------------------------------------------------------------

provider = {
  # GCS project name
  project          = "project-name"
  region           = "europe-west1"
}


gke_cluster_remote_state = {
  # Bucket with gke cluster state
  bucket  = "bucket-name"
  prefix = "bucket-name"
}
