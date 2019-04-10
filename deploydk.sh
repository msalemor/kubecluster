#!/bin/bash

# Set the host name
HOSTNAME=kmaster

# Update the hostname
sudo echo "$HOSTNAME" > /etc/hostname

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

# Verify docker
sudo docker run --rm hello-world

# Echo remember to reboot or logout
echo To logout execute: su - ${USER}
