resource "google_cloudbuild_trigger" "build_trigger" {
  name            = coalesce(var.build_name, "${var.gh_repo_name}-build")
  description     = "Managed by Terraform"
  tags            = ["build"]
  service_account = var.service_account_email
  location        = var.location

  github {
    owner = var.gh_repo_owner
    name  = var.gh_repo_name

    push {
      tag = var.tag_pattern
    }
  }

  build {
    step {
      name       = "gcr.io/cloud-builders/docker"
      entrypoint = "bash"
      args = [
        "-c",
        join(" && ", [
          # Create and use a buildx builder (harmless if already exists)
          "docker buildx create --use || true",

          # Build + push with full tag set and registry-based cache
          join(" ", flatten([
            "docker buildx build",
            "--file=${var.dockerfile}",
            "--cache-from=type=registry,ref=${var.image_name}:cache",
            "--cache-to=type=registry,ref=${var.image_name}:cache,mode=max",
            "--tag=${var.image_name}:$TAG_NAME",
            "--tag=${var.image_name}:latest",
            [
              for tag in var.additional_tags :
              "--tag=${var.image_name}:${tag}-$TAG_NAME"
            ],
            "--push",
            var.context
          ]))
        ])
      ]
    }

    dynamic "options" {
      for_each = var.machine_type != null ? [1] : []
      content {
        machine_type = var.machine_type
        logging      = "CLOUD_LOGGING_ONLY"
      }
    }

    timeout = var.timeout
  }
}
