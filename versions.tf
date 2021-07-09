terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "2.8.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "3.74.0"
    }
  }
  
  required_version = "~> 0.14"
}