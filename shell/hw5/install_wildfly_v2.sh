#!/bin/bash

# Update and upgrade system packages
sudo apt update && sudo apt upgrade -y

# Install Zenity for graphical dialog boxes
sudo apt-get install zenity -y

# Prompt for the public hostname
PUBLIC_HOSTNAME=$(zenity --entry --title="Enter Public Hostname" --text="Please enter your public hostname:")

# Check if the user clicked cancel or if the input is empty
if [ $? -ne 0 ] || [ -z "$PUBLIC_HOSTNAME" ]; then
    zenity --error --text="No hostname entered. Exiting script."
    exit 1
fi

# Install Apache HTTP
sudo apt install apache2 -y

# Setup SSL
sudo mkdir -p /etc/apache2/ssl

# Generate self-signed SSL certificate
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/apache2/ssl/apache.key -out /etc/apache2/ssl/apache.crt

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

# Install WildFly
WILDFLY_VERSION=26.0.1.Final
wget https://download.jboss.org/wildfly/$WILDFLY_VERSION/wildfly-$WILDFLY_VERSION.tar.gz
tar xf wildfly-$WILDFLY_VERSION.tar.gz
sudo mv wildfly-$WILDFLY_VERSION /opt/wildfly

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

# Add a new user for WildFly
sudo useradd -s /sbin/nologin wildfly

# Change the owner of the WildFly directory
sudo chown -R wildfly:wildfly /opt/wildfly

# Start and enable WildFly service
sudo systemctl daemon-reload
sudo systemctl start wildfly
sudo systemctl enable wildfly
