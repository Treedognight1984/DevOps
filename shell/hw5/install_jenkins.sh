#!/bin/bash

# Upgrade system packages
sudo apt update && sudo apt upgrade -y

# Install Java
sudo apt install openjdk-11-jdk -y

# Install Apache HTTP
sudo apt install apache2 -y

# (You might need to add Jenkins source URL and keys here before installing Jenkins)

# Install Jenkins
sudo apt-get install jenkins

# Setup SSL
sudo mkdir -p /etc/apache2/ssl

# Generate self-signed SSL certificate
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/apache2/ssl/apache.key -out /etc/apache2/ssl/apache.crt

# Setup Apache
sudo bash -c 'cat > /etc/apache2/sites-available/000-default.conf << EOF
<VirtualHost *:80>
   ServerName localhost
   Redirect / https://localhost/
</VirtualHost>

<VirtualHost *:443>
   SSLEngine on
   SSLCertificateFile /etc/apache2/ssl/apache.crt
   SSLCertificateKeyFile /etc/apache2/ssl/apache.key

   ProxyRequests Off
   ProxyPreserveHost On
   ProxyPass / http://localhost:8080/
   ProxyPassReverse / http://localhost:8080/
</VirtualHost>
EOF'

# Check and handle if a proxy.conf already exists
if [ -e "/etc/apache2/mods-enabled/proxy.conf" ]; then
    sudo mv /etc/apache2/mods-enabled/proxy.conf /etc/apache2/mods-enabled/proxy.conf.old
fi

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

# Change HTTP_HOST in Jenkins default configuration
sudo sed -i 's/#HTTP_HOST=127.0.0.1/HTTP_HOST=127.0.0.1/' /etc/default/jenkins
sudo sed -i 's/#JENKINS_ARGS="--webroot=\/var\/cache\/\$NAME\/war --httpPort=\$HTTP_PORT"/JENKINS_ARGS="--webroot=\/var\/cache\/\$NAME\/war --httpPort=\$HTTP_PORT --httpListenAddress=$HTTP_HOST"/' /etc/default/jenkins

# Restart both services
sudo systemctl restart apache2
sudo systemctl restart jenkins
