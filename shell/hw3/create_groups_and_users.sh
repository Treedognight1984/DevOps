#!/bin/bash

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit
fi

# Update and install ACL if not already installed
if ! command -v setfacl >/dev/null; then
  if [ -f /etc/debian_version ]; then
    apt-get update
    apt-get install -y acl
  elif [ -f /etc/redhat-release ]; then
    yum -y install acl
  fi
fi

# Function to create group, user, and set permissions
create_group_with_user() {
  group=$1
  user=$2
  permission=$3
  directory=$4

  # Check and create group if it does not exist
  if ! grep -q ${group} /etc/group; then
    groupadd ${group}
    echo "Group ${group} has been created."
  else
    echo "Group ${group} already exists."
  fi

  # Check and create user if it does not exist, then add to group
  if ! id ${user} &>/dev/null; then
    useradd -m -g ${group} ${user}
    echo "User ${user} has been created and added to group ${group}."
  else
    echo "User ${user} already exists."
  fi

  # Set ACLs for the specified directory
  setfacl -d -m group:${group}:${permission} ${directory}
  echo "Permissions ${permission} set for group ${group} on ${directory}."
}

# Create groups, users, and set permissions
create_group_with_user "DevGroup" "dev_user" "rwx" "/var/www/html"
create_group_with_user "OpsGroup" "ops_user" "rwx" "/var/www/html"
create_group_with_user "TestGroup" "test_user" "rx" "/var/www/html"

# Give OpsGroup sudo privileges without password
echo "%OpsGroup ALL=(ALL:ALL) NOPASSWD:ALL" >> /etc/sudoers

# Warning message about OpsGroup privileges
echo "Warning: OpsGroup has been given unrestricted sudo access without a password prompt. This is a high-risk configuration."
