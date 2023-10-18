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

# Install Java
sudo apt install openjdk-11-jdk -y

# Install Apache HTTP
sudo apt install apache2 -y

# Install Jenkins
sudo apt-get install jenkins -y

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

# Setup proxy
sudo bash -c 'cat > /etc/apache2/mods-enabled/proxy.conf << EOF
<IfModule mod_proxy.c>
ProxyPass         /  http://localhost:8080/ nocanon
ProxyPassReverse  /  http://localhost:8080/
ProxyRequests     Off
AllowEncodedSlashes NoDecode

<Proxy http://localhost:8080/*>
  Order deny,allow
  Allow from all
</Proxy>
</IfModule>
EOF'

# Enable Apache mods
sudo a2enmod ssl
sudo a2enmod proxy
sudo a2enmod proxy_http
sudo a2enmod rewrite
sudo a2enmod headers

# Restart both services
sudo systemctl restart apache2
sudo systemctl restart jenkins
