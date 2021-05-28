resource "digitalocean_droplet" "master" {
  count  = 1
  image  = "ubuntu-20-04-x64"
  name   = "master-${count.index}"
  region = "fra1"
  size   = "s-2vcpu-4gb"
  private_networking  = true

  ssh_keys = [
      data.digitalocean_ssh_key.terraform.id
  ]

  provisioner "remote-exec" {

    connection {
      host        = self.ipv4_address
      type        = "ssh"
      user        = "root"
      private_key = file(var.pvt_key)
    }
  }

  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ANSIBLE_FORCE_COLOR=true ansible-playbook -v -u root -i '${self.ipv4_address},' --private-key ${var.pvt_key} -e 'pub_key=${var.pub_key} do_token=${var.do_token}' master-playbook.yaml"
  }

  # remove all loadbalancers from account
  # unfortunately terraform doesn't support using vars in destroy-time provisioners, we therefore access the "DO_PAT" env var directly in the playbook
  provisioner "local-exec" {
    when    = destroy
    command = "ANSIBLE_HOST_KEY_CHECKING=False ANSIBLE_FORCE_COLOR=true ansible-playbook -v cleanup-playbook.yaml"
  }
}

resource "digitalocean_droplet" "worker" {
  count  = 1
  image  = "ubuntu-20-04-x64"
  name   = "worker-${count.index}"
  region = "fra1"
  size   = "s-2vcpu-2gb"
  private_networking  = true

  # wait for master to fully provision, else joining won't work
  depends_on = [
    digitalocean_droplet.master,
  ]

  ssh_keys = [
      data.digitalocean_ssh_key.terraform.id
  ]

  provisioner "remote-exec" {

    connection {
      host        = self.ipv4_address
      type        = "ssh"
      user        = "root"
      private_key = file(var.pvt_key)
    }
  }

  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ANSIBLE_FORCE_COLOR=true ansible-playbook -v -u root -i '${self.ipv4_address},' --private-key ${var.pvt_key} -e 'pub_key=${var.pub_key}' worker-playbook.yaml"
  }
}

output "master_droplet_ssh_connection" {
  value = {
    for droplet in digitalocean_droplet.master:
    droplet.name => "ssh -i ${var.pvt_key} kubedev@${droplet.ipv4_address}"
  }
}

output "worker_droplet_ssh_connection" {
  value = {
    for droplet in digitalocean_droplet.worker:
    droplet.name => "ssh -i ${var.pvt_key} kubedev@${droplet.ipv4_address}"
  }
}