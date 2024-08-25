#!/bin/bash
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get install -y default-jdk wget gnupg
# To determine your distribution, run lsb_release -c or cat /etc/os-release 
# Example:echo "deb https://releases.jfrog.io/artifactory/artifactory-pro-debs xenial main" | sudo tee -a /etc/apt/sources.list; 
wget -qO - https://releases.jfrog.io/artifactory/api/gpg/key/public | sudo apt-key add -;
distribution=$(lsb_release -cs)
echo "deb https://releases.jfrog.io/artifactory/artifactory-pro-debs {distribution} main" | sudo tee -a /etc/apt/sources.list; 
sudo apt-get update && sudo apt-get install jfrog-artifactory-pro=7.90.8
sudo systemctl start artifactory
sudo systemctl enable artifactory