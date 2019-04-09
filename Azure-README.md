# Ubuntu 18.04 Kubernetes Cluster in Azure

This ia a guide to create a kubernetes cluster on Ubuntu 18.04 on a master (kmaster) and a node (knode1). You can easily add more nodes following these instructions.

## Requirements
- Ubuntu 18.04
- Lastest Docker CE
- Latest Kubernetes (kubectl, kubelet and kubeadm)

## Installation Steps

On Kmaster and knode1:

1. Create a resouce group (k8scluster-rg) in your preferred location
2. Create a VNet (I used 192.168.0.0/20, and the default subnet 192.168.0.0/24)
2. Deploy kmaster (with open SSH) and knode Ubuntu 18.04 LTS VMs in the the default subnet and set the IPs to static
2. Install Docker
3. Install Kubernetes

On kmaster:

1. Initialize the cluster using: kubeadm init
2. Initlialize the POD network

On knode1 (and any other nodes):

1. Join the nodes to the cluster using: kubeadm join

**Note:** specific steps to follow.

## Ubuntu Installation on kmaster and knode1 

### Install, Update and Upgrade Ubuntu

After the kmaster and knode1 VMs are provisioned, SSH into kmaster and update the packages. Do the same for knode1 by SSH from kmaster:

```
sudo apt update && sudo apt upgrade -y
```

### Setup a static IP

Go to the IP Configuration on the Azure blade for the resource group, and set the IPs to static:

For kmaster, I used:
```
IP 192.168.0.4
```

knode1, I used:
```
IP 192.168.0.5
```

### Update the HOSTS file

Update the hosts file so tha tht kmaster and knode1 can discover each other:

```
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

Run

```
sudo reboot
```

## Install Docker

Install the latest version of docker in kmaster and knode1:

```
# Get required packages
sudo apt install apt-transport-https ca-certificates curl software-properties-common

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

Install the latest version of the kubernetes files from the google repositories in kmaster and knode1:

```
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

**Important:** The output of this command provides instructions on:
1. How to get the credentials to log into the cluster 
2. The join command with the token and key to add other nodes. Make sure to backup the keys to be able to connect other nodes.

To start using your cluster, you need to run the following commands as a regular user after the command above has run (you will see these lines listed as part of the output):

```
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

## Join knode1 to the cluster

SSH into knode1 from kmaster, You can now join knode1 (and other nodes) by running the following command:

**Note:** The command below is part of the output of the init command

```
# You should have gotten the actual token when you ran kubeadm init on the step above
sudo kubeadm join 192.168.0.4:6443 --token <REPLACE HERE> --discovery-token-ca-cert-hash sha256:<REPLACE HERE>
```

## Deploy a Pod Network on master node

Deploy a Pod Network through the master node (kmaster). A pod network is a medium of communication between the nodes of a network. In this tutorial, we are deploying a Flannel pod network on our cluster through the following command:

```
# Deploy flannel
$ sudo kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
```

## Check Kubernetes

Kubernetes install many of the requiresed services on the **kube-system** namespace. Use the following command in order to view the status of the network:

```
# Check the pods
$ kubectl get nodes --all-namespaces

# Check the nodes
$ kubectl get pods --all-namespaces

# Check all
$ kubectl get all --all-namespaces
```

All pods should be on status Running.

## Installing Helm

```
# Download helm
mkdir Downloads && cd Downloads
wget https://storage.googleapis.com/kubernetes-helm/helm-v2.13.1-linux-amd64.tar.gz

# Move it to a bin directory
sudo mv linux-amd64/helm /usr/local/bin/helm

# Create the tiller service account
kubectl create serviceaccount --namespace kube-system tiller
kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
kubectl patch deploy --namespace kube-system tiller-deploy -p '{"spec":{"template":{"spec":{"serviceAccount":"tiller"}}}}'      

# Initialize helm
helm init --service-account tiller --upgrade
```

#### References:

Deploy Kubernetes on Ubuntu

https://vitux.com/install-and-deploy-kubernetes-on-ubuntu/

How to install docker on ubuntu

https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-ubuntu-18-04

Installing Helm:

https://helm.sh/docs/using_helm/#installing-helm
