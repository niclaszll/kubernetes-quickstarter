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
    command = "gcloud container clusters get-credentials ${var.project_id}-gke --zone=${var.zone}"
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
    command = "ANSIBLE_HOST_KEY_CHECKING=False ANSIBLE_FORCE_COLOR=true ansible-playbook --connection=local -e 'do_token=${var.do_token} acme_mail=${var.acme_mail} domain=${var.domain} production=${var.production} create_gke=true create_doks=false}' ansible/main.yaml"
  }

  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ANSIBLE_FORCE_COLOR=true ansible-playbook --connection=local -e 'install_mongodb=${var.install_mongodb} install_vernemq=${var.install_vernemq} install_emqx=${var.install_emqx}' ansible/applications.yaml"
  }
}

# TODO: add testing node