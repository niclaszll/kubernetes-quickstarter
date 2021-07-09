provider "digitalocean" {
  token = var.do_token
}

provider "google" {
  project = var.project_id
  region  = var.region
}

module "doks_cluster" {
  source                            = "./modules/doks"
  count                             = var.create_doks ? 1 : 0
  do_token                          = var.do_token
  acme_mail                         = var.acme_mail
  domain                            = var.domain
  production                        = var.production
  install_mongodb                   = var.install_mongodb
  install_vernemq                   = var.install_vernemq
  install_emqx                      = var.install_emqx
}

module "gke_cluster" {
  source                            = "./modules/gke"
  count                             = var.create_gke ? 1 : 0
  do_token                          = var.do_token
  acme_mail                         = var.acme_mail
  domain                            = var.domain
  production                        = var.production
  install_mongodb                   = var.install_mongodb
  install_vernemq                   = var.install_vernemq
  install_emqx                      = var.install_emqx
  project_id                        = var.project_id
  region                            = var.region
  zone                              = var.zone
  gke_username                      = var.gke_username
  gke_password                      = var.gke_password
  gke_num_nodes                     = var.gke_num_nodes
}