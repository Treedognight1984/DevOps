#!/bin/bash

# Check if Apache is running and WildFly is configured
if pgrep apache2 > /dev/null && systemctl is-active --quiet wildfly; then
  echo "Apache and WildFly are running."
else
  echo "Apache or WildFly is not running or properly configured. Starting WildFly and reloading Apache..."

  # Start WildFly
  systemctl start wildfly

  # Check if WildFly started successfully
  if systemctl is-active --quiet wildfly; then
    echo "WildFly started successfully."

    # Reload Apache to make sure it's configured to proxy to WildFly
    systemctl reload apache2

    echo "Apache reloaded."
  else
    echo "Failed to start WildFly. Check your WildFly configuration and try starting it manually."
  fi
fi
