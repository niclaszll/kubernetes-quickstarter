# Vagrant Kubernetes Setup

Single node Kubernetes cluster setup for local development based on Vagrant.

## Setup Virtualbox and Vagrant on macOS

`brew install --cask virtualbox`

`brew install --cask vagrant`

You may also use the official installers (especially on Windows).

## Usage

Start VM:

`vagrant up`

Connect to VM:

`vagrant ssh`

Stop VM:

`vagrant halt`

## Acknowledgement

Basic setup from [Liz Rice](https://medium.com/@lizrice/kubernetes-in-vagrant-with-kubeadm-21979ded6c63).
