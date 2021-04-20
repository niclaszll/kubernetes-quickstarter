# Vagrant Kubernetes Setup

Single node Kubernetes cluster setup with [kube-prometheus-stack](https://github.com/prometheus-operator/kube-prometheus) for local development based on Vagrant.

## Setup Virtualbox and Vagrant on macOS

```sh
brew install --cask virtualbox
```

```sh
brew install --cask vagrant
```

You may also use the official installers (especially on Windows).

## Usage

Start VM:

```sh
vagrant up
```

Connect to VM:

```sh
vagrant ssh
```

Stop VM:

```sh
vagrant halt
```

## Use Ingress to access Pods

Add the following rule to your hosts file:

```
192.168.99.110 grafana.kube-local.com prometheus.kube-local.com
```

Afterwards you can access Grafana and Prometheus by the respective URLs: [grafana.kube-local.com](grafana.kube-local.com) or [prometheus.kube-local.com](prometheus.kube-local.com)

Default Grafana credentials:

- Username: `admin`
- Password: `prom-operator`

If this combination does not work, you can alternatively get the password with the following command:

```sh
kubectl get secret --namespace monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
```

## Acknowledgement

Basic setup from [Liz Rice](https://medium.com/@lizrice/kubernetes-in-vagrant-with-kubeadm-21979ded6c63).
