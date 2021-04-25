# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.provider "virtualbox" do |v|
    v.memory = 2048
    v.cpus = 2
  end
  
  # master node
  config.vm.define "master" do |master|
    master.vm.box = "bento/ubuntu-20.04"
    master.vm.hostname = "master"
    master.vm.network "private_network", ip: "192.168.99.100"
    master.vm.provision "docker"
    master.vm.synced_folder "./src", "/home/vagrant/src"  
    master.vm.provision "shell", path: "master-install.sh"
  end
  
  # worker node
  config.vm.define "worker" do |worker|
    worker.vm.box = "bento/ubuntu-20.04"
    worker.vm.hostname = "worker"
    worker.vm.network "private_network", ip: "192.168.99.101"
    worker.vm.provision "docker"
    worker.vm.provision "shell", path: "worker-install.sh"
  end
end