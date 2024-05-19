variable "gh_repo_owner" {
  type = string
}

variable "gh_repo_name" {
  type = string
}

# variable "image_name" {
#   type = string
#   default = null
# }

variable "image_name" {
  type        = string
  description = "should look something like asia-northeast1-docker.pkg.dev/pragmatic-parking-dev/containers/IMAGE_NAME. The cloud build service account assumes access is provided to upload to this"
}


variable "environments" {
  description = "List of maps, each representing an environment's build configuration"
  type = list(object({
    environment = string
    buildArgs   = map(string)
  }))
  default = []
}


variable "timeout" {
  type        = string
  default     = "3600s"
  description = "how long can this build run for? default is 1 hour."
}

variable "machine_type" {
  type    = string
  default = null
}

variable "parallelism" {
  type    = bool
  default = false
}

variable "context" {
  type        = string
  default     = "."
  description = "where is the Dockerfile located?"
}

variable "build_name" {
  type        = string
  default     = null
  description = "what is the name of the build trigger"
}
