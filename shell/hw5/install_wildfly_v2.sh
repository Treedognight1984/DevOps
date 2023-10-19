#!/bin/bash

# Update and upgrade system packages
sudo apt update && sudo apt upgrade -y

# Install Apache HTTP
sudo apt install apache2 -y

# Setup SSL
sudo mkdir -p /etc/apache2/ssl

# Generate self-signed SSL certificate
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/apache2/ssl/apache.key -out /etc/apache2/ssl/apache.crt

# Set your public hostname here (e.g., your EC2 instance's public IP or domain)
PUBLIC_HOSTNAME="ec2-184-72-123-139.compute-1.amazonaws.com"

# Setup Apache
sudo bash -c 'cat > /etc/apache2/sites-available/000-default.conf << EOF
<VirtualHost *:80>
   ServerName $PUBLIC_HOSTNAME
   Redirect / https://$PUBLIC_HOSTNAME/
</VirtualHost>

<VirtualHost *:443>
   ServerName $PUBLIC_HOSTNAME
   SSLEngine on
   SSLCertificateFile /etc/apache2/ssl/apache.crt
   SSLCertificateKeyFile /etc/apache2/ssl/apache.key

   ProxyRequests Off
   ProxyPreserveHost On
   ProxyPass / http://localhost:8080/
   ProxyPassReverse / http://localhost:8080/
</VirtualHost>
EOF'

# Enable Apache mods
sudo a2enmod ssl
sudo a2enmod proxy
sudo a2enmod proxy_http
sudo a2enmod rewrite
sudo a2enmod headers

# Restart Apache
sudo systemctl restart apache2

# Install WildFly (Update the version and URL as needed)
WILDFLY_VERSION="30.0.0.Final"
WILDFLY_URL="https://github.com/wildfly/wildfly/releases/download/$WILDFLY_VERSION/wildfly-$WILDFLY_VERSION.zip"

# Install unzip (if not already installed)
sudo apt-get install unzip -y

# Create the /opt/wildfly directory
sudo mkdir -p /opt/wildfly

# Download and extract WildFly
wget "$WILDFLY_URL" -O wildfly.zip
unzip wildfly.zip
sudo mv wildfly-$WILDFLY_VERSION/* /opt/wildfly

# Configure WildFly as a service
sudo bash -c 'cat > /etc/systemd/system/wildfly.service << EOF
[Unit]
Description=WildFly Full
After=network.target
[Service]
User=wildfly
ExecStart=/opt/wildfly/bin/standalone.sh -b=0.0.0.0
ExecReload=/opt/wildfly/bin/jboss-cli.sh --connect command=:reload
[Install]
WantedBy=default.target
EOF'

# Add a new user for WildFly (if not already created)
sudo useradd -s /sbin/nologin wildfly

# Change the owner of the WildFly directory
sudo chown -R wildfly:wildfly /opt/wildfly

# Start and enable WildFly service
sudo systemctl daemon-reload
sudo systemctl start wildfly
sudo systemctl enable wildfly
