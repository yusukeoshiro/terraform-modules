resource "google_cloudbuild_trigger" "build_trigger" {
  name            = coalesce(var.build_name, "${var.gh_repo_name}-build")
  description     = "Managed by Terraform"
  tags            = ["build"]
  service_account = var.service_account_email

  github {
    owner = var.gh_repo_owner
    name  = var.gh_repo_name

    push {
      # something that looks like v1.1.1 or v1.1.1-rc1
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
          "docker pull ${var.image_name}:latest || echo 'No cache available'",

          # Build image with all tags
          join(" ", flatten([
            "docker build",
            "--file=${var.dockerfile}",
            "--cache-from=${var.image_name}:latest",
            "--tag=${var.image_name}:$TAG_NAME",
            [
              for tag in var.additional_tags :
              "--tag=${var.image_name}:${tag}-$TAG_NAME"
            ],
            "."
          ])),

          # Push all tags
          "docker push ${var.image_name}:$TAG_NAME",
          join(" && ", [
            for tag in var.additional_tags :
            "docker push ${var.image_name}:${tag}-$TAG_NAME"
          ])
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
