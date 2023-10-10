#!/bin/bash

# Update and install dependencies
sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install -y openjdk-11-jdk wget

# Set Java Home. Replace the path if your Java installation directory is different
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64

# Download and unzip WildFly
WILDFLY_VERSION=29.0.1.Final
cd /opt

# Remove old installation if exists
if [ -d "/opt/wildfly" ]; then
  echo "Removing old WildFly installation..."
  sudo rm -rf /opt/wildfly*
fi

sudo wget https://github.com/wildfly/wildfly/releases/download/$WILDFLY_VERSION/wildfly-$WILDFLY_VERSION.tar.gz
sudo tar -zxvf wildfly-$WILDFLY_VERSION.tar.gz
WILDFLY_FOLDER=$(tar -tzf wildfly-$WILDFLY_VERSION.tar.gz | head -1 | cut -f1 -d"/")
sudo ln -s /opt/$WILDFLY_FOLDER /opt/wildfly
sudo rm wildfly-$WILDFLY_VERSION.tar.gz

# Setup SSL
KEYSTORE_PASSWORD=changeit # Change this password
KEYSTORE_DIR="/opt/wildfly/standalone/configuration/"
if [ ! -d "$KEYSTORE_DIR" ]; then
  sudo mkdir -p "$KEYSTORE_DIR"
fi
sudo keytool -genkeypair -keyalg RSA -keysize 2048 -keystore "$KEYSTORE_DIR/keystore.jks" -storepass $KEYSTORE_PASSWORD -noprompt -dname "CN=localhost, OU=YourOrgUnit, O=YourOrg, L=YourCity, ST=YourState, C=YourCountryCode"
sudo /opt/wildfly/bin/jboss-cli.sh --connect --command="embed-server, socket-binding-group=standard-sockets:socket-binding=https:add(port=8443),/subsystem=undertow/server=default-server/https-listener=https:add(socket-binding=https, security-realm=ssl-realm)"
sudo /opt/wildfly/bin/jboss-cli.sh --connect --command="embed-server, /subsystem=elytron/key-store=myks:add(path=keystore.jks, relative-to=jboss.server.config.dir, credential-reference={clear-text=\"$KEYSTORE_PASSWORD\"}, type=JKS)"
sudo /opt/wildfly/bin/jboss-cli.sh --connect --command="embed-server, /subsystem=elytron/key-manager=mykm:add(key-store=myks, credential-reference={clear-text=\"$KEYSTORE_PASSWORD\"})"
sudo /opt/wildfly/bin/jboss-cli.sh --connect --command="embed-server, /subsystem=elytron/server-ssl-context=myssc:add(key-manager=mykm, protocols=[\"TLSv1.2\"])"
sudo /opt/wildfly/bin/jboss-cli.sh --connect --command="embed-server, /subsystem=undertow/server=default-server/https-listener=https:write-attribute(name=ssl-context, value=myssc)"

# Start WildFly
sudo /opt/wildfly/bin/standalone.sh &