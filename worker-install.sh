#! /bin/bash
# Install kubernetes
echo "[kube-install] Installing Kubernetes"
apt-get update && apt-get install -y apt-transport-https
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF
apt-get update
apt-get install -y kubelet kubeadm kubectl mosquitto-clients nfs-common sshpass

echo "[prepare] Turning of swap"
# kubelet requires swap off
swapoff -a
# keep swap off after reboot
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

echo "[kubeadm] Joining cluster"
sudo /vagrant/join.sh