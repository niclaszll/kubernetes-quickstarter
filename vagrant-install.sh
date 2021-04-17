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

# Writing the IP address to a file in the shared folder 
echo $IPADDR > /vagrant/ip-address.txt

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
    "address": "0.0.0.0"
scheduler:
  extraArgs:
    "address": "0.0.0.0"
EOF

# Set up Kubernetes
NODENAME=$(hostname -s)
kubeadm init --config=kubeadm-config.yaml

# Set up admin creds for the vagrant user
echo Copying credentials to /home/vagrant...
sudo --user=vagrant mkdir -p /home/vagrant/.kube
cp -i /etc/kubernetes/admin.conf /home/vagrant/.kube/config
chown $(id -u vagrant):$(id -g vagrant) /home/vagrant/.kube/config

# Install a pod network (e.g. Weave)
echo Installing Weave...
sudo -u vagrant kubectl apply -f https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')

# Allow pods to run on master node
echo Tainting nodes...
sudo -u vagrant kubectl taint nodes --all node-role.kubernetes.io/master-

# Install Helm
echo Installing Helm...
curl -s https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash

# Install Prometheus
echo Installing kube-prometheus-stack...
sudo -u vagrant helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
sudo -u vagrant helm repo update
sudo -u vagrant kubectl create ns monitoring
sudo -u vagrant helm install prometheus prometheus-community/kube-prometheus-stack -n monitoring