#!/bin/bash
# Update package index
sudo apt-get update -y
sudo apt-get upgrade -y

sudo apt-get install -y postgresql postgresql-contrib
sudo systemctl start postgresql
sudo systemctl enable postgresql
sudo -u postgres psql -c "CREATE USER artifactory WITH PASSWORD 'password';"
sudo -u postgres psql -c "CREATE DATABASE artifactory_db OWNER artifactory;"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE artifactory_db TO artifactory;"


sudo apt-get install -y wget curl

# Install JFrog Artifactory
wget -qO - https://releases.jfrog.io/artifactory/api/gpg/key/public | gpg --dearmor | sudo tee /usr/share/keyrings/jfrog-archive-keyring.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/jfrog-archive-keyring.gpg] https://releases.jfrog.io/artifactory/artifactory-debs jammy main" | sudo tee /etc/apt/sources.list.d/jfrog.list
sudo apt-get update -y
sudo apt-get install jfrog-artifactory-oss -y

sudo adduser --system --no-create-home --group artifactory

sudo chown -R artifactory:artifactory /opt/jfrog/artifactory

sudo mkdir -p /opt/jfrog/artifactory/etc
echo "db.type=postgres" | sudo tee /opt/jfrog/artifactory/etc/db.properties
echo "db.driver=org.postgresql.Driver" | sudo tee -a /opt/jfrog/artifactory/etc/db.properties
echo "db.url=jdbc:postgresql://localhost:5432/artifactory_db" | sudo tee -a /opt/jfrog/artifactory/etc/db.properties
echo "db.username=artifactory" | sudo tee -a /opt/jfrog/artifactory/etc/db.properties
echo "db.password=password" | sudo tee -a /opt/jfrog/artifactory/etc/db.properties
sudo chmod 640 /opt/jfrog/artifactory/etc/db.properties

# Create systemd service for Artifactory
sudo cat <<EOF | sudo tee /etc/systemd/system/artifactory.service
[Unit]
Description=JFrog Artifactory
After=network.target

[Service]
Type=simple
User=artifactory
ExecStart=/opt/jfrog/artifactory/app/bin/artifactory.sh start
ExecStop=/opt/jfrog/artifactory/app/bin/artifactory.sh stop
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable artifactory
sudo systemctl start artifactory