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
192.168.99.110 grafana.kube-local.com prometheus.kube-local.com alertmanager.kube-local.com
```

Afterwards you can access Grafana, Prometheus and the Alertmanager by their respective URLs: [grafana.kube-local.com](http://grafana.kube-local.com), [prometheus.kube-local.com](http://prometheus.kube-local.com) and [alertmanager.kube-local.com](http://alertmanager.kube-local.com).

Default Grafana credentials:

- Username: `admin`
- Password: `prom-operator`

If this combination does not work, you can alternatively get the password with the following command:

```sh
kubectl get secret --namespace monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
```

## Making changes to the kube-prometheus-stack helm chart values at runtime

```
helm upgrade -f /path/to/values.yaml prometheus prometheus-community/kube-prometheus-stack -n monitoring
```

## Acknowledgement

Basic setup from [Liz Rice](https://medium.com/@lizrice/kubernetes-in-vagrant-with-kubeadm-21979ded6c63).
