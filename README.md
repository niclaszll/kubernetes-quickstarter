# Kubernetes Setup

Multi node Kubernetes cluster setup with [kube-prometheus-stack](https://github.com/prometheus-operator/kube-prometheus) for cloud deployment on DigitalOcean (self-managed or in [DOKS](https://www.digitalocean.com/products/kubernetes/)).

## Installation

Make sure you have [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html), the [Ansible Kubernetes Collection](https://galaxy.ansible.com/community/kubernetes) and [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli) installed on your system.

If you want to use the DOKS-Setup, you also need to install [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl), [Helm](https://helm.sh/docs/intro/install/) and [doctl](https://github.com/digitalocean/doctl).

### Setup SSH for Digital Ocean (only needed for self-managed cluster setup)

You will need to add a new SSH keypair to your DigitalOcean account. Open a terminal and run the following command:

```sh
ssh-keygen
```

You will be prompted to save and name the key.

```
Generating public/private rsa key pair. Enter file in which to save the key (/Users/USER/.ssh/id_rsa):
```

This will generate two files, by default called `id_rsa` and `id_rsa.pub`. Next, copy and paste the contents of the .pub file, typically `id_rsa.pub`, into the SSH key content field in the `Add SSH Key` section under your [DigitalOcean account security settings](https://cloud.digitalocean.com/account/security). For more information, see the [DigitalOcean Docs](https://docs.digitalocean.com/products/droplets/how-to/add-ssh-keys/to-account/).

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

To initialize Terraform, run the following command once inside the `cloud-do-self-managed/` or `cloud-doks/` directory:

```sh
terraform init
```

## Usage

_Run the following commands inside the `cloud-do-self-managed/` or `cloud-doks/` directory._

Provision resources:

```sh
terraform apply -var "do_token=${DO_PAT}" -auto-approve
```

In the case of the self-managed cluster, SSH connection details will be printed to your console once Terraform has successfully finished provisioning all resources.

If you are using the DOKS setup, you can access the cluster directly using `kubectl` without connecting via SSH first, since Terraform automatically adds the credentials for your cluster to your local `kubeconfig`.

Destroy resources:

```sh
terraform destroy -var "do_token=${DO_PAT}" -auto-approve
```

Load balancers and block storage will be destroyed through a destroy-time provisioner, using the DigitalOcean API, as they are not directly managed by Terraform.

### Access monitoring applications

Grafana, Prometheus and the Alertmanager are respectively accessible on the subdomains `grafana.*`, `prometheus.*` and `alertmanager.*` of your Domain. It may take a few seconds till all pods are started.