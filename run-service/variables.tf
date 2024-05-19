variable "service_name" {
  type = string
}

variable "region_name" {
  type = string
  # default = "asia-northeast1"
}

variable "protect_with_iap" {
  type    = bool
  default = false
}

variable "iap_client_id" {
  type    = string
  default = "INVALID_VALUE"
}

variable "iap_client_secret" {
  type    = string
  default = "INVALID_VALUE"
}

variable "env" {
  type        = string
  default     = "dev"
  description = "dev | stg | prd"
}

variable "iap_members" {
  type        = list(string)
  default     = []
  description = "who can access this iap resource?"
}

variable "image" {
  type    = string
  default = "gcr.io/cloudrun/hello"
}

variable "service_account" {
  type    = string
  default = null
}

variable "service_annotations" {
  type    = map(any)
  default = {}
}

variable "spec_annotations" {
  type    = map(any)
  default = {}
}

variable "allow_unauthenticated" {
  type    = bool
  default = false
}

variable "envs" {
  description = "Environment variables for the cloud run service"
  type = map(object({
    value       = optional(string)
    secret_name = optional(string)
    secret_key  = optional(string, "latest")
  }))
  default = {}
}



variable "volumes" {
  type = list(object({
    name           = string
    secret         = string
    mount_path     = string
    secret_version = optional(string, "latest")
  }))
  default = []
}

variable "memory" {
  type    = string
  default = "512Mi"
}

variable "cpu" {
  type    = string
  default = "1000m"
}

variable "continuous_deploy" {
  type        = bool
  default     = false
  description = "if true it will build and deploy every time there is a push in the branch"
}

variable "gh_repo_owner" {
  type    = string
  default = null
}

variable "gh_repo_name" {
  type    = string
  default = null
}

variable "gh_branch" {
  type    = string
  default = "dev"
}

variable "context" {
  type    = string
  default = "."
}

variable "registry_name" {
  type    = string
  default = ""
}

variable "container_port" {
  type    = number
  default = 8080
}
