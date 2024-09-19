# Create dummy cloud run service to define cloud run service URL
resource "google_cloud_run_service" "run_service" {
  name     = "${var.service_name}-${var.region_name}"
  location = var.region_name

  template {
    spec {
      dynamic "volumes" {
        for_each = var.volumes
        content {
          name = volumes.value.name
          secret {
            secret_name = volumes.value.secret
            items {
              key  = volumes.value.secret_version
              path = "."
            }
          }
        }
      }
      containers {
        ports {
          container_port = var.container_port
        }
        dynamic "volume_mounts" {
          for_each = var.volumes
          content {
            name       = volume_mounts.value.name
            mount_path = volume_mounts.value.mount_path
          }
        }
        resources {
          requests = {
            memory = var.memory
            cpu    = var.cpu
          }
          limits = {
            memory = var.memory
            cpu    = var.cpu
          }
        }

        image = var.image
        dynamic "env" {
          for_each = var.envs
          content {
            name  = env.key
            value = env.value.value != null ? env.value.value : null
            dynamic "value_from" {
              for_each = env.value.secret_name != null && env.value.secret_key != null ? [1] : []
              content {
                secret_key_ref {
                  name = env.value.secret_name
                  key  = env.value.secret_key
                }
              }
            }
          }
        }
      }
      service_account_name = var.service_account
    }

    metadata {
      annotations = var.spec_annotations
    }
  }

  metadata {
    labels = {
      "deployed_by" = "terraform"
    }
    annotations = var.service_annotations
  }
}

resource "google_cloud_run_service_iam_member" "invoker" {
  count    = var.allow_unauthenticated ? 1 : 0
  location = var.region_name
  service  = google_cloud_run_service.run_service.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}



# Create serverss network end point group
resource "google_compute_region_network_endpoint_group" "neg" {
  name                  = "${var.service_name}-${var.region_name}"
  network_endpoint_type = "SERVERLESS"
  region                = var.region_name
  cloud_run {
    service = google_cloud_run_service.run_service.name
  }
}


resource "google_compute_backend_service" "backend" {
  name     = "backend-${var.service_name}"
  protocol = "HTTPS"
  backend {
    group = google_compute_region_network_endpoint_group.neg.id
  }

  dynamic "iap" {
    for_each = var.protect_with_iap ? [1] : []
    content {
      oauth2_client_id     = var.iap_client_id
      oauth2_client_secret = var.iap_client_secret
    }
  }
}


resource "google_compute_region_backend_service" "backend" {
  name                  = "rgn-backend-${var.service_name}"
  region                = var.region_name
  load_balancing_scheme = "INTERNAL_MANAGED"
  protocol              = "HTTP"
  backend {
    group          = google_compute_region_network_endpoint_group.neg.id
    balancing_mode = "UTILIZATION"
  }
}


# data "google_iam_policy" "iap_dev_and_stg" {
#   binding {
#     role = "roles/iap.httpsResourceAccessor"
#     members = [
#       "domain:oshiro.app",
#       "group:contractors@pragtech.jp"
#     ]
#   }
# }

data "google_iam_policy" "policy" {
  binding {
    role    = "roles/iap.httpsResourceAccessor"
    members = var.iap_members
  }
}

resource "google_iap_web_backend_service_iam_policy" "default" {
  count               = var.protect_with_iap ? 1 : 0
  web_backend_service = google_compute_backend_service.backend.name
  policy_data         = data.google_iam_policy.policy.policy_data
}



resource "google_cloudbuild_trigger" "continuous_deploy" {
  count       = var.continuous_deploy ? 1 : 0
  name        = "cd-${google_cloud_run_service.run_service.name}"
  description = "Managed by Terraform"
  tags        = ["deploy"]
  github {
    owner = var.gh_repo_owner
    name  = var.gh_repo_name
    push {
      branch = "^${var.gh_branch}$"
    }
  }

  build {
    step {
      name = "gcr.io/kaniko-project/executor:latest"
      args = [
        "--context=${var.context}",
        "--destination=${var.registry_name}/${var.gh_repo_name}:latest",
        "--cache=true"
      ]
    }

    step {
      name = "gcr.io/cloud-builders/gcloud"
      args = [
        "run",
        "deploy",
        "${google_cloud_run_service.run_service.name}",
        "--image=${var.registry_name}/${var.gh_repo_name}:latest",
        "--region=${var.region_name}",
      ]
    }
  }
}
