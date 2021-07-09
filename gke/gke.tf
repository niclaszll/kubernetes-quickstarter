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

# GKE cluster
resource "google_container_cluster" "primary" {
  name     = "${var.project_id}-gke"
  location = var.zone
  
  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  network    = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.subnet.name

  # disable stackdriver logging and monitoring
  logging_service = "none"
  monitoring_service = "none"

  # configure local kubeconfig to access cluster via kubectl
  provisioner "local-exec" {
    command = "gcloud container clusters get-credentials $(terraform output -raw kubernetes_cluster_name) --zone=$(terraform output -raw zone)"
  }
}

# Separately Managed Node Pool
resource "google_container_node_pool" "primary_nodes" {
  name       = "${google_container_cluster.primary.name}-node-pool"
  location   = var.zone
  cluster    = google_container_cluster.primary.name
  node_count = var.gke_num_nodes

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

    labels = {
      env = var.project_id
    }

    # preemptible  = true
    machine_type = "n1-standard-1"
    tags         = ["gke-node", "${var.project_id}-gke"]
    metadata = {
      disable-legacy-endpoints = "true"
    }
  }

  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ANSIBLE_FORCE_COLOR=true ansible-playbook --connection=local -e 'do_token=${var.do_token} acme_mail=${var.acme_mail} domain=${var.domain} production=${var.production}' ansible/main-playbook.yaml"
  }
}

