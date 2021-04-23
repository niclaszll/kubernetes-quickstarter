#! /bin/sh

# Install kubernetes
apt-get update && apt-get install -y apt-transport-https
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF
apt-get update
apt-get install -y kubelet kubeadm kubectl

# kubelet requires swap off
swapoff -a

# keep swap off after reboot
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Get the IP address that VirtualBox has given this VM
IPADDR=`ip -4 address show dev eth1 | grep inet | awk '{print $2}' | cut -f1 -d/`
echo This VM has IP address $IPADDR

cat > kubeadm-config.yaml <<EOF
apiVersion: kubeadm.k8s.io/v1beta2
kind: InitConfiguration
localAPIEndpoint:
  advertiseAddress: $IPADDR
  bindPort: 6443
---
apiVersion: kubeadm.k8s.io/v1beta2
kind: ClusterConfiguration
clusterName: local-dev
apiServer:
  CertSANs:
  - "$IPADDR"
controllerManager:
  extraArgs:
    "bind-address": "0.0.0.0"
    "port": "10252"
scheduler:
  extraArgs:
    "bind-address": "0.0.0.0"
    "port": "10251"
EOF

# Set up Kubernetes
kubeadm init --config=kubeadm-config.yaml
export KUBECONFIG=/etc/kubernetes/admin.conf

# Set up admin creds for the vagrant user
echo "Configure access to cluster for $(logname)"
mkdir -p /home/$(logname)/.kube
sudo cp /etc/kubernetes/admin.conf /home/$(logname)/.kube/config
sudo chown $(logname):$(logname) /home/$(logname)/.kube/config

# Install a pod network (e.g. Weave)
echo Installing Weave...
kubectl apply -f https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')

# Allow pods to run on master node
echo Tainting nodes...
kubectl taint nodes --all node-role.kubernetes.io/master-

# Install Helm
echo Installing Helm...
curl -s https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash

# Install Prometheus
echo Installing kube-prometheus-stack...
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
kubectl create ns monitoring
helm install prometheus prometheus-community/kube-prometheus-stack -n monitoring

# Install MetalLB
echo Installing MetalLB...
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.6/manifests/namespace.yaml
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.6/manifests/metallb.yaml
kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"

cat << EOF > /tmp/metallb-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: metallb-system
  name: config
data:
  config: |
    address-pools:
    - name: default
      protocol: layer2
      addresses:
      - 192.168.99.110-192.168.99.150
EOF

kubectl create -f /tmp/metallb-config.yaml

# Install ingress-nginx
echo Installing ingress-nginx...
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

kubectl create ns ingress-nginx

# important: set custom values!
helm install my-ingress-nginx ingress-nginx/ingress-nginx --set hostNetwork=true --set hostPort.enabled=true --set kind=DaemonSet -n ingress-nginx

# fix for "failed calling webhook" error
# see: https://stackoverflow.com/a/63021823
kubectl delete -A ValidatingWebhookConfiguration my-ingress-nginx-admission -n ingress-nginx

# Deploy Ingress
echo Deploying Ingress...
cat << EOF > /tmp/ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: minimal-ingress
  namespace: monitoring
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
    - host: grafana.kube-local.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: prometheus-grafana
                port:
                  number: 3000
    - host: prometheus.kube-local.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: prometheus-kube-prometheus-prometheus
                port:
                  number: 9090
    - host: alertmanager.kube-local.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: prometheus-kube-prometheus-alertmanager
                port:
                  number: 9093
EOF

kubectl create -f /tmp/ingress.yaml