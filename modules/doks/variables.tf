#
# General
#

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

variable "install_emqx" {
  type        = bool
  description = "Should EMQ X be installed"
}