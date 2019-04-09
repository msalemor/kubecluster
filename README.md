# kubecluster

A a guide to create a kubernetes cluster on Ubuntu 18.04 on a master (kmaster) and a node (knode1). You can easily add more nodes following these instructions.

## Requirements
- Ubuntu 18.04
- Docker CE
- Kubernetes (kubectl and kubeadm)

## Ubuntu Installation for kmaster and knode1 

### Update and Upgrade Ubuntu
Install Ubuntu 18.04, update and upgrade. After installing Ubuntu 18.04 run:

sudo apt update && sudo apt upgrade -y

### Setup a static IP
For kmaster and knode, setup a static ip (I used the Gui):

kmaster
```
IP 10.0.2.100
netmask 255.255.255.0
gateway 10.0.2.1
dns-nameserver 8.8.8.8
```

knode1 
```
IP 10.0.2.1001
netmask 255.255.255.0
dns-nameserver 8.8.8.8
```

### Change the host names

kmaster
```
sudo hostnamectl set-hostname kmaster
```

knode 1
```
sudo hostnamectl set-hostname knode1
```

### Update the hosts file

Run:

```
sudo nano /etc/hostnames
```
And add the following entries:

kmaster
```
localhost 127.0.0.1
kmaster 127.0.0.1
kmaster 10.0.2.100
knode1 10.0.2.101
```

knode
```
localhost 127.0.0.1
knode1 127.0.0.1
kmaster 10.0.2.100
knode1 10.0.2.101
```

### Turn off swap


In kmaster and knode, turn off the swap file

```
sudo swapoff -a
sudo nano /etc/fstab and comment out the line that has swap and save the file.
```

### Reboot the machines

Run

```
sudo reboot
```

## Install Docker

Install the latest version of docker:

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
sudo apt install docker-ce

# Verify docker
sudo systemctl status docker

# Add the current user to the user group so that you don't have to type sudo in front of the docker command
sudo usermod -aG docker ${USER}

# Logout and apply new user to the group
su - ${USER}
```

### Install Kubeadnm, kubectl and kubelet

Install the latest version of the kubernetes files from the google repositories:

```
# Install the kubernetes signing kys
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add

# Add the repository
sudo apt-add-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main"

# Install kubeadm, kubectl and kubelet
sudo apt install kubeadm
```
