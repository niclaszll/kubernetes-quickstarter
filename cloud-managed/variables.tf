#
# General
#

variable "create_doks" {
  type        = bool
  description = "Create DOKS cluster"
}

variable "create_gke" {
  type        = bool
  description = "Create GKE cluster"
}

variable "do_token" {
  type        = string
  description = "DigitalOcean Personal Access Token for External-DNS"
}

variable "acme_mail" {
  type        = string
  description = "Email adress for Let's Encrypt certificate issuing"
}

variable "domain" {
  type        = string
  description = "Domain on which the cluster will run"
}

variable "production" {
  type        = bool
  description = "If false, only a staging TLS certificate is issued"
}

#
# Applications
#

variable "install_mongodb" {
  type        = bool
  description = "Should MongoDB be installed"
}

variable "install_vernemq" {
  type        = bool
  description = "Should VerneMQ be installed"
}

variable "install_emqx" {
  type        = bool
  description = "Should EMQ X be installed"
}

#
# GKE specifics
#

variable "project_id" {
  description = "project id"
}

variable "region" {
  description = "region"
}

variable "zone" {
  description = "zone"
}

variable "gke_username" {
  default     = ""
  description = "gke username"
}

variable "gke_password" {
  default     = ""
  description = "gke password"
}

variable "gke_num_nodes" {
  default     = 2
  description = "number of gke nodes"
}