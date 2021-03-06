# Install a kubernetes cluster with Helm on Ubuntu 18.04 VMs in Azure

This ia a guide to create a kubernetes cluster on Ubuntu 18.04 on a master (kmaster) and a node (knode1). You can easily add more nodes following these instructions.

## Requirements

- Ubuntu 18.04
- Lastest Docker CE
- Latest Kubernetes (kubectl, kubelet and kubeadm)
- Familiarity executing sudo commands in Ubuntu
- Familiarity editing files using command line editors such as nano, vim, etc.
- Familiarity creating resources in Azure; particularly VNets, subnets and Ubuntu VMs
- Familiarity connecting to VMs in Azure over SSH

## Installation Steps

On Kmaster and knode1:

1. Create a resouce group (k8scluster-rg) in your preferred location
2. Create a VNet (i.e. 192.168.0.0/20, and the default subnet (i.e. 192.168.0.0/24)
3. Deploy two Ubuntu 18.04 VMs to the default subnet having static IPs.
- kmaster (public IP with open SSH)
- knode1 
4. Install Docker
5. Install Kubernetes

On kmaster:

1. Initialize the cluster using: kubeadm init
2. Initlialize the POD network

On knode1 (and any other nodes):

1. Join the nodes to the cluster using: kubeadm join

> **Note:** detailed installation steps to follow.

## Ubuntu Installation on kmaster and knode1 

### Install, Update and Upgrade Ubuntu

After the kmaster and knode1 VMs are provisioned, SSH into kmaster and update the packages. Do the same for knode1 by SSH from kmaster:

```bash
sudo apt update && sudo apt upgrade -y
```

### Setup a static IP

Go to the IP Configuration on the Azure blade for the resource group, and set the IPs for each of the VMs to static:

For kmaster, I used:
```
IP 192.168.0.4
```

knode1, I used:
```
IP 192.168.0.5
```

### Update the HOSTS file

Update the hosts file so tha kmaster and knode1 can discover each other. SSH into kmaster and update the hosts file. SSH into knode1 from kmaster and do the same.

```bash
sudo nano /etc/hosts
```

And add the following entries:

For kmaster:
```
localhost 127.0.0.1
kmaster 192.168.0.4
knode1 192.168.0.5
```

For knode1:
```
localhost 127.0.0.1
kmaster 192.168.0.4
knode1 192.168.0.5
```

### Reboot the kmaster and knode1

Reboot knode1 and kmaster. SSH into knode1 from kmaster first and execute the command. From kmaster execute the same command.

```bash
sudo reboot
```

## Install Docker

To install Docker, SSH into kmaster and run the following commands. Also, SSH into knode1 from kmaster and execute the same commands.

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

# Verify docker
sudo systemctl status docker

# Add the current user to the user group so that you don't have to type sudo in front of the docker command
sudo usermod -aG docker ${USER}

# Logout and apply new user to the group
su - ${USER}

# Verify docker
docker run --rm hello-world
```

## Install Kubeadnm, kubectl and kubelet

To install Kubernetes, SSH into kmaster and run the following commands. Also, SSH into knode1 from kmaster and execute the same commands.

```bash
# Install the kubernetes signing keys
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add

# Add the repository
sudo apt-add-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main"

# Install kubeadm, kubectl and kubelet (these command will install all three)
sudo apt install kubeadm -y
```

## Start kubernetes on the master node

To start the kubernetes cluster on the master node (kmaster), SSH into kmaster and run the following command:

```bash
sudo kubeadm init --pod-network-cidr=10.244.0.0/16
```

**Important:** The output of this command provides instructions on:
1. How to get the credentials to log into the cluster 
2. The join command with the token and key to add other nodes. Make sure to backup the keys to be able to connect other nodes.

To start using your cluster, you need to run the following commands as a regular user after the command above has run (you will see these lines listed as part of the output):

```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

## Join knode1 to the cluster

To join knode1 to the cluster, SSH into knode1 from kmaster, and execute the following command:

> **Important:** The command below is part of the output of the init command above where you can obtain the toekn and cert

```bash
# You should have gotten the actual token when you ran kubeadm init on the step above
sudo kubeadm join 192.168.0.4:6443 --token <REPLACE HERE> --discovery-token-ca-cert-hash sha256:<REPLACE HERE>
```

## Deploy a Pod Network on master node

Deploy a Pod Network through the master node (kmaster). A pod network is a medium of communication between the nodes of a network. I'm using flannel, but there are others.

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

> **Note:** All pods should be on Running status.

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
