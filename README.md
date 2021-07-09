# Kubernetes Setup

Multi node Kubernetes cluster setup with [kube-prometheus-stack](https://github.com/prometheus-operator/kube-prometheus), deployed on [GKE](https://cloud.google.com/kubernetes-engine) or [DigitalOcean Kubernetes (DOKS)](https://www.digitalocean.com/products/kubernetes/).

## Installation

Make sure you have the following software installed on your system:

- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)
- [Ansible Kubernetes Collection](https://galaxy.ansible.com/community/kubernetes)
- [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)
- [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl)
- [Helm](https://helm.sh/docs/intro/install/)
- [doctl](https://github.com/digitalocean/doctl) (only DOKS)

### Setup Domain on Digital Ocean

To use your own domain, you need to add it to your DigitalOcean account and [update your domain’s NS records to point to DigitalOcean’s name servers](https://www.digitalocean.com/community/tutorials/how-to-point-to-digitalocean-nameservers-from-common-domain-registrars). Later, all necessary A-records are automatically created via [ExternalDNS](https://github.com/kubernetes-sigs/external-dns) to point the domain to the load balancer.

### Create Personal Access Token in DigitalOcean

You first need to [create a Personal Access Token in DigitalOcean](https://docs.digitalocean.com/reference/api/create-personal-access-token/). Terraform will use your DigitalOcean Personal Access Token to communicate with the DigitalOcean API and manage resources in your account. **Don’t share this key with others, and keep it out of scripts and version control!** Export your DigitalOcean Personal Access Token to an environment variable called `DO_PAT`. This will make using it in subsequent commands easier and keep it separate from your code:

```sh
export DO_PAT="YOUR_PERSONAL_ACCESS_TOKEN"
```

I would recommend adding this line to your shell configuration files to avoid having to do this step again in the future.

### Setup Terraform

You may also want to enable logging to Standard Output (STDOUT), so you can see what Terraform is trying to do. Do that by running the following command, or again, directly adding it to your shell configuration files.

```sh
export TF_LOG=1
```

Now make a copy of `terraform.tfvars.example`, rename it to `terraform.tfvars` and define all variables within.

To initialize Terraform, run the following command once:

```sh
terraform init
```

## Usage

Provision resources:

```sh
terraform apply -var "do_token=${DO_PAT}" -auto-approve
```

You can access the cluster directly using `kubectl`, since Terraform automatically adds the credentials for your cluster to your local `kubeconfig`.

Destroy resources:

```sh
terraform destroy -var "do_token=${DO_PAT}" -auto-approve
```

**Attention! (only DOKS)**: Load balancers and block storage will be destroyed through a destroy-time provisioner, using the DigitalOcean API, as they are not directly managed by Terraform. **All LB and Block Storage resources in the account will be destroyed!** If this is not desired, then deactivate the destroy-time provisioner.

### Access monitoring applications

Grafana, Prometheus and the Alertmanager are respectively accessible on the subdomains `grafana.*`, `prometheus.*` and `alertmanager.*` of your domain. It may take a few seconds till all pods are started.