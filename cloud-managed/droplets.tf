resource "digitalocean_kubernetes_cluster" "kubernetes_cluster" {
  name    = "priobike-do-cluster"
  region  = "fra1"
  version = "1.20.7-do.0"

  # This default node pool is mandatory
  node_pool {
    name       = "default-pool"
    size       = "s-2vcpu-4gb"
    auto_scale = true
    min_nodes  = 2
    max_nodes  = 3
  }

  # configure local kubeconfig to access cluster via kubectl
  provisioner "local-exec" {
    command = "doctl kubernetes cluster kubeconfig save priobike-do-cluster"
  }

  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ANSIBLE_FORCE_COLOR=true ansible-playbook --connection=local -e 'do_token=${var.do_token} acme_mail=${var.acme_mail} domain=${var.domain} production=${var.production}' ansible/main-playbook.yaml"
  }

  # remove all loadbalancers from account
  # unfortunately terraform doesn't support using vars in destroy-time provisioners, we therefore access the "DO_PAT" env var directly in the playbook
  provisioner "local-exec" {
    when    = destroy
    command = "ANSIBLE_HOST_KEY_CHECKING=False ANSIBLE_FORCE_COLOR=true ansible-playbook --connection=local -v ansible/cleanup-playbook.yaml"
  }
}