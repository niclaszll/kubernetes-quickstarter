terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "2.8.0"
    }
  }
}

variable "do_token" {}
variable "acme_mail" {}
variable "domain" {}
variable "production" {}

provider "digitalocean" {
  token = var.do_token
}