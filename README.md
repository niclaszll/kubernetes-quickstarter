# Kubernetes Setup

Multi node Kubernetes cluster setup with [kube-prometheus-stack](https://github.com/prometheus-operator/kube-prometheus) for local development and cloud deployment on DigitalOcean.

## Cloud Deployment with Terraform and Ansible

### Install necessary tools

```sh
brew install ansible
brew install terraform
ansible-galaxy collection install community.kubernetes
```

You may also use the official installers (especially on Windows).

### Setup development environment

**Digital Ocean**

You will need to add a new SSH keypair to your DigitalOcean account. Open a terminal and run the following command:

```sh
ssh-keygen
```

You will be prompted to save and name the key.

```
Generating public/private rsa key pair. Enter file in which to save the key (/Users/USER/.ssh/id_rsa): 
```

This will generate two files, by default called `id_rsa` and `id_rsa.pub`. Next, copy and paste the contents of the .pub file, typically `id_rsa.pub`, into the SSH key content field in the `Add SSH Key` section under your [DigitalOcean account security settings](https://cloud.digitalocean.com/account/security). For more information, see [DigitalOcean Docs](https://docs.digitalocean.com/products/droplets/how-to/add-ssh-keys/to-account/).

To use your own domain, you first need to add it to your DigitalOcean account and [update your domain’s NS records to point to DigitalOcean’s name servers](https://www.digitalocean.com/community/tutorials/how-to-point-to-digitalocean-nameservers-from-common-domain-registrars). After that change the domains under `terraform/setup/kubernetes/ingress.yaml` from *.priobike-demo.de to your own domain. Later, the necessary A-records are automatically created via [ExternalDNS](https://github.com/kubernetes-sigs/external-dns) to point the domain to the load balancer.

**Terraform**

You first need to [create a Personal Access Token in DigitalOcean](https://docs.digitalocean.com/reference/api/create-personal-access-token/). Terraform will use your DigitalOcean Personal Access Token to communicate with the DigitalOcean API and manage resources in your account. **Don’t share this key with others, and keep it out of scripts and version control!** Export your DigitalOcean Personal Access Token to an environment variable called `DO_PAT`. This will make using it in subsequent commands easier and keep it separate from your code:

```sh
export DO_PAT="YOUR_PERSONAL_ACCESS_TOKEN"
```

I would recommend adding this line to your shell configuration files to avoid having to do this step again in the future.

You may also want to enable logging to Standard Output (STDOUT), so you can see what Terraform is trying to do. Do that by running the following command, or again, directly adding it to your shell configuration files.

```sh
export TF_LOG=1
```

### Usage

Provision resources:
```sh
terraform apply -var "do_token=${DO_PAT}" -var "pvt_key=/Users/<USERNAME>/.ssh/id_rsa" -var "pub_key=/Users/<USERNAME>/.ssh/id_rsa.pub" -auto-approve
```

Connect to node:
```sh
ssh -i /Users/<USERNAME>/.ssh/id_rsa kubedev@<NODE_IP>
```

Destroy resources:
```sh
terraform destroy -var "do_token=${DO_PAT}" -var "pvt_key=/Users/<USERNAME>/.ssh/id_rsa" -var "pub_key=/Users/<USERNAME>/.ssh/id_rsa.pub" -auto-approve
```

Load balancers will be destroyed through a destroy-time provisioner, using the DigitalOcean API, as they are not directly managed by Terraform.

**TODO**
- https
- master post install

## Local Development with Virtualbox, Vagrant and Ansible

### Install necessary tools

```sh
brew install --cask virtualbox
brew install --cask vagrant
brew install ansible
ansible-galaxy collection install community.kubernetes
```

You may also use the official installers (especially on Windows).

### Usage

Start VM:

```sh
vagrant up
```

Connect to VM:

```sh
vagrant ssh master
vagrant ssh worker
```

### Use Ingress to access Pods without a domain (for local testing)

Add the following rule to your hosts file:

```
<EXTERNAL_IP_OF_YOUR_NGINX_INGRESS_SVC> grafana.kube-local.com prometheus.kube-local.com alertmanager.kube-local.com
```

Afterwards you can access Grafana, Prometheus and the Alertmanager by their respective URLs: [grafana.kube-local.com](http://grafana.kube-local.com), [prometheus.kube-local.com](http://prometheus.kube-local.com) and [alertmanager.kube-local.com](http://alertmanager.kube-local.com).

Default Grafana credentials:

- Username: `admin`
- Password: `prom-operator`

If this combination does not work, you can alternatively get the password with the following command:

```sh
kubectl get secret --namespace monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
```