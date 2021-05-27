#! /bin/bash
echo "[post-install] Setting up dynamic volume provisioning"
# install nfs-subdir-external-provisioner
helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner
helm install nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner --set nfs.server=192.168.99.100 --set nfs.path=/var/nfs/general --set storageClass.defaultClass=true

echo "[post-install] Setting up mongo-kubernetes-operator"
git clone https://github.com/mongodb/mongodb-kubernetes-operator.git /tmp/mongo-operator
# Install Custom Resource Definitions
kubectl apply -f /tmp/mongo-operator/config/crd/bases/mongodbcommunity.mongodb.com_mongodbcommunity.yaml
# Install necessary roles and role-bindings
kubectl create ns mongo
kubectl apply -k /tmp/mongo-operator/config/rbac/ -n mongo
# Install Operator
kubectl create -f /tmp/mongo-operator/config/manager/manager.yaml -n mongo

echo "[post-install] Deploying MongoDB"
kubectl create -f /home/vagrant/setup/kubernetes/mongo-config.yaml -n mongo

echo "[post-install] Deploying VerneMQ"
kubectl create ns mqtt
helm repo add vernemq https://vernemq.github.io/docker-vernemq
helm install -f /home/vagrant/setup/helm/vernemq-helm-values.yaml vernemq vernemq/vernemq -n mqtt