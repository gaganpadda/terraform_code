#!/bin/bash
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get install -y default-jdk wget gnupg
curl -fsSL https://releases.jfrog.io/artifactory/api/gpg/key/public | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/jfrog.gpg
distribution=$(lsb_release -cs)
echo "deb https://releases.jfrog.io/artifactory/artifactory-pro-debs {distribution} main" | sudo tee -a /etc/apt/sources.list; 
sudo apt-get update && sudo apt-get install jfrog-artifactory-pro
sudo systemctl start artifactory
sudo systemctl enable artifactory
