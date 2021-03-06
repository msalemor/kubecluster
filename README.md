# Install a kubernetes cluster with Helm on Ubuntu 18.04

This ia a guide to create a kubernetes cluster on Ubuntu 18.04 on a master (kmaster) and a node (knode1). You can easily add more nodes following these instructions.

## Requirements
- Ubuntu 18.04
- Lastest Docker CE
- Latest Kubernetes (kubectl, kubelet and kubeadm)
- In my case, I used VirtualBox

## Installation Steps

On Kmaster and knode1:

1. Setup Ubuntu
2. Install Docker
3. Install Kubernetes

On kmaster:

1. Initialize the cluster using: kubeadm init
2. Initlialize the POD network

On knode1 (and any other nodes):

1. Join the nodes to the cluster using: kubeadm join

> **Note:** detailed installation steps to follow.

## Ubuntu Installation on kmaster and knode1 

### Install, Update and Upgrade Ubuntu

Install Ubuntu 18.04. In downloaded Ubuntu 18.04 desktop and installed it on VirtualBox using a NAT network (10.0.2.0/24).

After installing Ubuntu, update and upgrade the packages by running:

```bash
sudo apt update && sudo apt upgrade -y
```

### Setup a static IP

For kmaster and knode1, setup a static ip (I used the graphical user interface):

For kmaster, I used:
```text
IP 10.0.2.100
netmask 255.255.255.0
gateway 10.0.2.1
dns-nameserver 8.8.8.8
```

knode1, I used:
```
IP 10.0.2.1001
netmask 255.255.255.0
gateway 10.0.2.1
dns-nameserver 8.8.8.8
```

### Change the host names

In my case, I had to update the hostnames because I had clonned the machines, so I changed the host names.

kmaster
```bash
sudo hostnamectl set-hostname kmaster
```

knode1
```bash
sudo hostnamectl set-hostname knode1
```

### Update the HOSTS file

Update the hosts file so tha tht kmaster and knode1 so that they can discover each other:

```bash
sudo nano /etc/hosts
```

And add the following entries:

For kmaster:
```
localhost 127.0.0.1
kmaster 10.0.2.100
knode1 10.0.2.101
```

For knode1:
```
localhost 127.0.0.1
kmaster 10.0.2.100
knode1 10.0.2.101
```

### Turn off the swap file


In kmaster and knode, turn off the swap file

```bash
sudo swapoff -a

# Edit the fstab file, comment out the line that has swap partition, and save the file.
# It is possible that you install Ubuntu without a swap file, so you can skip this step
sudo nano /etc/fstab 
```

### Reboot the machines

Reboot kmaster and knode1:

```bash
sudo reboot
```

## Install Docker

Install the latest version of docker in kmaster and knode1:

### Install Docker the short way

```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
```

### Install Docker the long way

```bash
# Get required packages
sudo apt install apt-transport-https ca-certificates curl software-properties-common -y

# Add the key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

# Add the repository
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"

# Update the packages
sudo apt update

# Install docker
sudo apt install docker-ce -y
```

## Verify docker

```
sudo systemctl status docker
```

## Add the current user to the user group so that you don't have to type sudo in front of the docker command

```
sudo usermod -aG docker ${USER}
```

## Logout and apply new user to the group

```
su - ${USER}
```

## Verify docker
```
docker run --rm hello-world
```

## Install Kubeadnm, kubectl and kubelet

Install the latest version of the kubernetes files from the google repositories in kmaster and knode1:

```bash
# Install the kubernetes signing keys
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add

# Add the repository
sudo apt-add-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main"

# Install kubeadm, kubectl and kubelet (these command will install all three)
sudo apt install kubeadm -y
```

## Start kubernetes on the master node

To start the kubernetes cluster on the master node (kmaster), run the following command:

```
sudo kubeadm init --pod-network-cidr=10.244.0.0/16
```

> **Important:** The output of this command provides instructions to get the credentials to log into the cluster and the keys to add other nodes. Make sure to backup the keys to be able to connect other nodes.

To start using your cluster, you need to run the following as a regular user:

```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

## Join knode1 to the cluster

You can now join knode1 (and other nodes) by running the following command:

```bash
# Replace the token and cert which you should have gotten on the step above
sudo kubeadm join 10.0.2.100:6443 --token <REPLACE HERE> --discovery-token-ca-cert-hash sha256:<REPLACE HERE>
```

## Deploy a Pod Network

Deploy a Pod Network through the master node (kmaster) running the command below. A pod network is a medium of communication between the nodes of a network. I am using Flannel but there are other:

```bash
# Deploy flannel
$ sudo kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
```

## Check Kubernetes

Kubernetes install many of the requiresed services on the **kube-system** namespace. Use the following command in order to view the status of the network:

```bash
# Check the pods
$ kubectl get nodes --all-namespaces

# Check the nodes
$ kubectl get pods --all-namespaces

# Check all
$ kubectl get all --all-namespaces
```

> **Note:** All pods in the kube-system namespace should have a status of Running.

## Installing Helm

```bash
# Download helm
mkdir Downloads && cd Downloads
wget https://storage.googleapis.com/kubernetes-helm/helm-v2.13.1-linux-amd64.tar.gz

# Move helm to a bin directory in the PATH
sudo mv linux-amd64/helm /usr/local/bin/helm

# Create the tiller service account
kubectl create serviceaccount --namespace kube-system tiller
kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
kubectl patch deploy --namespace kube-system tiller-deploy -p '{"spec":{"template":{"spec":{"serviceAccount":"tiller"}}}}'      

# Initialize helm
helm init --service-account tiller --upgrade
```

#### References:

- Deploy Kubernetes on Ubuntu
  - https://vitux.com/install-and-deploy-kubernetes-on-ubuntu/
- How to install docker on ubuntu
  - https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-ubuntu-18-04
- Installing Helm:
  - https://helm.sh/docs/using_helm/#installing-helm

