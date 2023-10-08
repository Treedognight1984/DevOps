#!/bin/bash

# Function to install apache2 based on the detected operating system
install_apache2() {
  # Detect operating system
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
  else
    echo "Cannot detect the operating system."
    exit 1
  fi

  # Install apache2 based on the operating system
  case $OS in
  "Ubuntu" | "Debian GNU/Linux")
    apt-get update
    apt-get install -y apache2
    ;;
  "CentOS Linux")
    yum -y update
    yum -y install httpd
    systemctl start httpd
    systemctl enable httpd
    ;;
  *)
    echo "Unsupported operating system: ${OS}"
    exit 1
    ;;
  esac

  echo "Apache2 installation is complete."
}

# Run the function to install apache2
install_apache2
