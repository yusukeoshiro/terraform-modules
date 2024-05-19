resource "google_cloudbuild_trigger" "build_trigger" {
  name        = coalesce(var.build_name, "${var.gh_repo_name}-build")
  description = "Managed by Terraform"
  tags        = ["build"]

  github {
    owner = var.gh_repo_owner
    name  = var.gh_repo_name

    push {
      # something that looks like v1.1.1 or v1.1.1-rc1
      tag = "^v[0-9]+(\\.[0-9]+){2}(-rc[0-9]+)?$"
    }
  }

  build {
    dynamic "step" {
      for_each = length(var.environments) > 0 ? toset(var.environments) : toset([{ "environment" = "default", buildArgs = {} }])
      content {
        name = "gcr.io/kaniko-project/executor:latest"
        args = flatten([
          "--context=${var.context}",
          "--destination=${var.image_name}:${length(var.environments) > 0 ? "${step.value.environment}-" : ""}$TAG_NAME",
          "--cache=true",
          [
            for key, value in step.value.buildArgs : "--build-arg=${key}=${value}"
          ]
        ])
        id       = step.value.environment
        wait_for = var.parallelism ? ["-"] : null
      }
    }

    dynamic "options" {
      for_each = var.machine_type != null ? [1] : []
      content {
        machine_type = var.machine_type
      }
    }

    timeout = var.timeout
  }
}

