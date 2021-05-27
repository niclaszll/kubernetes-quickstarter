# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.ssh.insert_key = false

  config.vm.provider "virtualbox" do |v|
    v.linked_clone = true
    v.memory = 2048
    v.cpus = 2
  end
  
  # master node
  config.vm.define "master" do |master|
    master.vm.box = "bento/ubuntu-20.04"
    master.vm.hostname = "master"
    master.vm.network "private_network", ip: "192.168.99.100"
    master.vm.synced_folder "./src", "/home/vagrant/src"  
    master.vm.synced_folder "./setup", "/home/vagrant/setup"  
    master.vm.provision "ansible" do |ansible|
      ansible.verbose = "v"
      ansible.playbook = "setup/master-playbook.yaml"
      ansible.extra_vars = {
          node_ip: "192.168.99.100",
      }
    end
  end
  
  # worker node
  config.vm.define "worker" do |worker|
    worker.vm.box = "bento/ubuntu-20.04"
    worker.vm.hostname = "worker"
    worker.vm.network "private_network", ip: "192.168.99.101"
    worker.vm.provision "ansible" do |ansible|
      ansible.playbook = "setup/worker-playbook.yaml"
      ansible.verbose = "v"
      ansible.extra_vars = {
          node_ip: "192.168.99.101",
      }
    end
    # todo: also provision via ansible
    worker.vm.provision "shell", inline: "sshpass -pvagrant ssh -oStrictHostKeyChecking=no vagrant@192.168.99.100 'sh /home/vagrant/setup/master-post-install.sh' && exit"
  end
end