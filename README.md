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
- [gcloud SDK](https://cloud.google.com/sdk/docs/install) (only GKE)

### Setup Domain

To set up a domain name, you need to purchase a domain name from a domain name registrar and then set up DNS records for it. This setup assumes that DigitalOcean is used to manage DNS records (both for the GKE and DOKS setup). For this you need to add your domain to your DigitalOcean account and [update your domain’s NS records to point to DigitalOcean’s name servers](https://www.digitalocean.com/community/tutorials/how-to-point-to-digitalocean-nameservers-from-common-domain-registrars). Later, all necessary A-records are automatically created via [ExternalDNS](https://github.com/kubernetes-sigs/external-dns) to point your domain to the load balancer.

> You may need to manually delete DNS records when switching between DOKS and GKE clusters, as ExternalDNS sometimes does not update records correctly

### Create Personal Access Token in DigitalOcean

You need to [create a Personal Access Token in DigitalOcean](https://docs.digitalocean.com/reference/api/create-personal-access-token/). Terraform (and other tools like ExternalDNS) will use your DigitalOcean Personal Access Token to communicate with the DigitalOcean API and manage resources in your account. **Don’t share this key with others, and keep it out of scripts and version control!** Export your DigitalOcean Personal Access Token to an environment variable called `DO_PAT`. This will make using it in subsequent commands easier and keep it separate from your code:

```sh
export DO_PAT="YOUR_PERSONAL_ACCESS_TOKEN"
```

I would recommend adding this line to your shell configuration files to avoid having to do this step again in the future.

### Setup GKE

After you've installed the gcloud SDK, initialize it by running the following command to authorize the SDK to access GCP using your user account credentials and add the SDK to your PATH:

```sh
gcloud init
```

Finally, add your account to the Application Default Credentials (ADC). This will allow Terraform to access these credentials to provision resources on GCloud.

```sh
gcloud auth application-default login
```

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

> **Important (only DOKS):** Load balancers and block storage will be destroyed through a destroy-time provisioner, using the DigitalOcean API, as they are not directly managed by Terraform and are also not automatically destroyed when the cluster is destroyed (as is the case with GKE). **All LB and Block Storage resources in your account will be destroyed!** If this is not desired, then deactivate the destroy-time provisioner.

### Access monitoring applications

Grafana, Prometheus and the Alertmanager are respectively accessible on the subdomains `grafana.*`, `prometheus.*` and `alertmanager.*` of your domain. It may take a few seconds till all pods are started.