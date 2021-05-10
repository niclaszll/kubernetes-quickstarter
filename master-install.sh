#! /bin/bash
JOIN_FILE=/vagrant/join.sh
chmod +x $JOIN_FILE

# Install kubernetes
echo "[kube-install] Installing Kubernetes"
apt-get update && apt-get install -y apt-transport-https
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF
apt-get update
apt-get install -y kubelet kubeadm kubectl bash-completion

# enable kubectl auto-completion
source /usr/share/bash-completion/bash_completion
echo 'source <(kubectl completion bash)' >> /home/vagrant/.bashrc
source /home/vagrant/.bashrc

echo "[prepare] Turning of swap"
# kubelet requires swap off
swapoff -a
# keep swap off after reboot
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Get the IP address that VirtualBox has given this VM
echo "[prepare] Retrieving IP adress of node"
IPADDR=`ip -4 address show dev eth1 | grep inet | awk '{print $2}' | cut -f1 -d/`
echo "[prepare] This VM has IP address $IPADDR"

echo "[kube-install] Initialising cluster with kubeadm"
# Move kubeadm-config template to tmp and replace $IPADDR var
cp /home/vagrant/src/setup/kubeadm-config.yaml /tmp/kubeadm-config.yaml
sed -i "s/vIPADDR/$IPADDR/g" /tmp/kubeadm-config.yaml

# Init cluster and create join script for other nodes
kubeadm init --config=/tmp/kubeadm-config.yaml | grep -Ei "kubeadm join|discovery-token-ca-cert-hash" > ${JOIN_FILE}
export KUBECONFIG=/etc/kubernetes/admin.conf

# Set up admin creds for the vagrant user
echo "[post-install] Configuring access to cluster for user $(logname)"
mkdir -p /home/$(logname)/.kube
sudo cp /etc/kubernetes/admin.conf /home/$(logname)/.kube/config
sudo chown $(logname):$(logname) /home/$(logname)/.kube/config

# Install a pod network (e.g. Weave)
echo "[post-install] Installing Weave"
kubectl apply -f https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')

# Allow pods to run on master node
echo "[post-install] Tainting nodes"
kubectl taint nodes --all node-role.kubernetes.io/master-

# Install Helm
echo "[post-install] Installing Helm"
curl -s https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash

# Install Prometheus
echo "[post-install] Installing kube-prometheus-stack"
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
kubectl create ns monitoring
helm install prometheus prometheus-community/kube-prometheus-stack -n monitoring

# Install MetalLB
echo "[post-install] Installing MetalLB"
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.6/manifests/namespace.yaml
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.6/manifests/metallb.yaml
kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"

kubectl create -f /home/vagrant/src/setup/metallb-config.yaml

# Install ingress-nginx
echo "[post-install] Installing ingress-nginx"
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

kubectl create ns ingress-nginx
# important: set custom values!
helm install my-ingress-nginx ingress-nginx/ingress-nginx --set hostNetwork=true --set hostPort.enabled=true --set kind=DaemonSet -n ingress-nginx
# fix for "failed calling webhook" error
# see: https://stackoverflow.com/a/63021823
kubectl delete -A ValidatingWebhookConfiguration my-ingress-nginx-admission -n ingress-nginx

# Deploy Ingress
echo "[post-install] Deploying Ingress"
kubectl create -f /home/vagrant/src/setup/ingress.yaml

# Install VerneMQ
kubectl create ns mqtt
helm repo add vernemq https://vernemq.github.io/docker-vernemq
helm install vernemq vernemq/vernemq -n mqtt --set additionalEnv[0].name=DOCKER_VERNEMQ_ACCEPT_EULA,additionalEnv[0].value="yes",additionalEnv[1].name=DOCKER_VERNEMQ_ALLOW_ANONYMOUS,additionalEnv[1].value="on"


